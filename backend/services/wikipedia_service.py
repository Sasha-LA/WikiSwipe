import httpx
from typing import List, Dict

WIKI_API_URL = "https://en.wikipedia.org/w/api.php"

async def search_articles(topic: str, limit: int = 5) -> List[str]:
    import random
    async with httpx.AsyncClient(headers={"User-Agent": "WikiSwipeApp/1.0 (contact@example.com)"}) as client:
        params = {
            "action": "query",
            "list": "search",
            "srsearch": topic,
            "utf8": "",
            "format": "json",
            "srlimit": limit,
            "sroffset": random.randint(0, 80)
        }
        response = await client.get(WIKI_API_URL, params=params)
        data = response.json()
        search_results = data.get("query", {}).get("search", [])
        return [item["title"] for item in search_results]

async def get_article_content_and_image(title: str) -> Dict:
    async with httpx.AsyncClient(headers={"User-Agent": "WikiSwipeApp/1.0 (contact@example.com)"}) as client:
        params = {
            "action": "query",
            "prop": "extracts|pageimages",
            "titles": title,
            "format": "json",
            "exintro": 1,
            "explaintext": 1,
            "pithumbsize": 800
        }
        response = await client.get(WIKI_API_URL, params=params)
        data = response.json()
        pages = data.get("query", {}).get("pages", {})
        
        if not pages or "-1" in pages:
            return {"title": title, "content": "", "image_url": None, "url": f"https://en.wikipedia.org/wiki/{title.replace(' ', '_')}"}
        
        page = list(pages.values())[0]
        content = page.get("extract", "")
        image_url = None
        if "thumbnail" in page:
            image_url = page["thumbnail"].get("source")
            
        return {
            "title": title,
            "content": content,
            "image_url": image_url,
            "url": f"https://en.wikipedia.org/wiki/{title.replace(' ', '_')}"
        }
