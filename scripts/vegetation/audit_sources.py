"""Read only public Sketchfab metadata; never scrape viewer/source binaries or credentials."""
import concurrent.futures
import datetime
import hashlib
import json
import pathlib
import urllib.error
import urllib.request

SOURCES = [
    ("magic_igor", "Magic Tree", "Igor Zukowicz", "ba0869cea1944722825abf4d18a6ae41"),
    ("magic_nyomryu", "Magic tree", "nyomryu", "9504051a9813488bb58f4019928f91fb"),
    ("fantasy_simon", "Fantasy Tree", "Šimon Ustal", "ec156d5983c141b19cc566b0b5d650a6"),
    ("oak_maple", "Oak Tree | Game Ready", "Maple", "2f4ae6b907fd4741abda5d1b71c83b10"),
    ("sakura_jogoss", "Sakura Tree 01", "Jogoss", "147ae7d0d332456a99ec6195e9b0cd4f"),
    ("cherry_sereib", "Japanese Cherry Tree", "Sereib", "7c9e7c4e971f4953b06faf300cbb1209"),
    ("stylized_voyage", "Stylized Tree", "Voyage", "69e0951f356c4a21ac60cd17f8462ad5"),
    ("stylized_stefan", "Stylized Tree", "stefan", "4475c38dac544c8abe49ffa602df6595"),
    ("curved_dungdao", "Stylized Tree", "dungdao", "b6fae70b2556459eafaf61f94e284c8b"),
]
OUTPUT = pathlib.Path("build/vegetation/source-audit")

def inspect(source):
    key, name, author, uid = source
    url = f"https://api.sketchfab.com/v3/models/{uid}"
    result = dict(key=key, requestedName=name, requestedAuthor=author, uid=uid, api=url)
    try:
        request = urllib.request.Request(url, headers={"Accept": "application/json"})
        with urllib.request.urlopen(request, timeout=30) as response:
            data = response.read(2_000_000)
            model = json.loads(data)
        # Closed metadata roster, no thumbnails or viewer asset endpoints retained.
        result.update(status="METADATA_READ", name=model.get("name"),
                      author=model.get("user", {}).get("displayName"),
                      authorURL=model.get("user", {}).get("profileUrl"),
                      modelURL=model.get("viewerUrl"), license=model.get("license"),
                      downloadable=model.get("isDownloadable"), triangles=model.get("faceCount"),
                      vertices=model.get("vertexCount"), tags=[t.get("name") for t in model.get("tags", [])],
                      description=model.get("description"), responseSHA256=hashlib.sha256(data).hexdigest())
    except (urllib.error.URLError, ValueError) as error:
        result.update(status="BLOCKED_METADATA", error=str(error))
    return result

if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        results = list(executor.map(inspect, SOURCES))
    report = dict(checkedUTC=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  assetsDownloaded=0, models=results)
    (OUTPUT / "public-metadata.json").write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    for r in results:
        print(json.dumps({k:r.get(k) for k in ("key", "status", "author", "license", "downloadable", "triangles", "tags", "error")}, ensure_ascii=False))
