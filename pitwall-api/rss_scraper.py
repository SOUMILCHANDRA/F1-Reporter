import os
import json
import logging
from datetime import datetime, timezone
from dateutil import parser
import feedparser
from google import genai
from google.genai import types
from supabase import create_client, Client

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# RSS feeds
FEEDS = [
    "https://www.formula1.com/content/fom-website/en/latest/all.xml",
    "https://www.motorsport.com/rss/f1/news/",
    "https://www.racefans.net/feed/",
    "https://www.planetf1.com/feed",
    "https://www.the-race.com/formula-1/feed/",
    "https://www.autosport.com/rss/f1/news/"
]

ALLOWED_KEYWORDS = [
    "formula 1",
    "f1",
    "fia",
    "grand prix",
    "verstappen",
    "hamilton",
    "ferrari",
    "mercedes",
    "red bull",
    "mclaren",
]

def init_supabase() -> Client:
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_KEY")
    if not url or not key:
        return None
    return create_client(url, key)

def init_genai():
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return None
    return genai.Client(api_key=api_key)

def is_f1_article(title: str, client: genai.Client) -> dict:
    prompt = f"""You are an F1 news classifier.

Determine if the article is directly related to Formula 1.

Return JSON:

{{
 "is_f1": true/false,
 "confidence": 0-100
}}

Title:
{title}
"""
    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                temperature=0.1
            ),
        )
        return json.loads(response.text)
    except Exception as e:
        logger.error(f"Gemini classification failed for '{title}': {e}")
        return {"is_f1": False, "confidence": 0}

def fetch_and_filter_news():
    supabase = init_supabase()
    ai_client = init_genai()
    
    if not supabase:
        logger.error("Supabase credentials missing. Cannot save news.")
        return {"status": "error", "detail": "Supabase missing"}
        
    if not ai_client:
        logger.error("Gemini API key missing. Cannot classify news.")
        return {"status": "error", "detail": "Gemini missing"}

    articles = []
    
    for feed_url in FEEDS:
        logger.info(f"Fetching RSS: {feed_url}")
        try:
            feed = feedparser.parse(feed_url)
            for entry in feed.entries[:10]: # Check last 10 from each to avoid huge backlog
                title = entry.get('title', '')
                link = entry.get('link', '')
                
                # Basic keyword filter
                title_lower = title.lower()
                if not any(kw in title_lower for kw in ALLOWED_KEYWORDS):
                    continue
                
                # Check if already in DB
                try:
                    existing = supabase.table('f1_news').select('id').eq('url', link).execute()
                    if existing.data:
                        continue # Already processed
                except Exception as db_err:
                    logger.warning(f"DB check failed, likely table does not exist: {db_err}")
                    
                # AI Filter
                classification = is_f1_article(title, ai_client)
                if classification.get("is_f1") and classification.get("confidence", 0) > 80:
                    pub_date = entry.get('published', '')
                    try:
                        if pub_date:
                            dt = parser.parse(pub_date)
                            published_at = dt.isoformat()
                        else:
                            published_at = datetime.now(timezone.utc).isoformat()
                    except:
                        published_at = datetime.now(timezone.utc).isoformat()
                        
                    source = feed.feed.get('title', 'Unknown Source')
                    
                    articles.append({
                        "title": title,
                        "source": source,
                        "url": link,
                        "urlToImage": None, 
                        "description": entry.get('summary', ''),
                        "publishedAt": published_at,
                        "author": entry.get('author', ''),
                        "confidence": classification.get("confidence", 0)
                    })
        except Exception as e:
            logger.error(f"Failed to process feed {feed_url}: {e}")
            
    if articles:
        logger.info(f"Saving {len(articles)} validated articles to database.")
        try:
            supabase.table('f1_news').insert(articles).execute()
        except Exception as e:
            logger.error(f"Failed to insert articles: {e}")
            
    return {"status": "success", "processed_articles": len(articles)}

if __name__ == "__main__":
    from dotenv import load_dotenv
    load_dotenv()
    fetch_and_filter_news()
