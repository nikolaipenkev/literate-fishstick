# Ultimate SEO Crawler 🚀

A high-performance, multi-threaded web crawler designed for SEO analysis. Uses Nokogiri, HTTParty, and Redis to extract and store SEO data efficiently.

## 📌 Features
✔ Multi-threaded crawling for speed  
✔ Extracts Title, Meta Description, H1, H2, H3, Canonical URL, Robots Meta, Word Count, Load Time, Page Size, Internal/External Links  
✔ Detects missing ALT attributes, broken links, HTTPS status, Google Analytics, and Tag Manager  
✔ Saves results in Redis and exports them as a text file

## 🛠 Installation
Ensure you have Ruby, Bundler, and Redis installed. Then:

```bash
git clone https://github.com/your-username/ultimate-seo-crawler.git
cd ultimate-seo-crawler
bundle install
```

## 🚀 Usage
Run the crawler on a target website:

```bash
ruby crawler.rb
```

## 📝 Configuration
You can adjust the depth and thread pool size when initializing the crawler:

```ruby
crawler = UltimateSEOCrawler.new('https://example.com', max_depth = 2, thread_pool_size = 10)
crawler.run
```

## 🗄 Viewing Results
After the crawl completes:

### Check Redis:
```bash
redis-cli KEYS "seo:*"
redis-cli GET "seo:https://example.com"
```

### Exported File:
```bash
cat seo_results.txt
```

## 🔧 Troubleshooting
1️⃣ **Redis not saving data?** Ensure Redis is running:

```bash
redis-server
redis-cli PING  # Should return PONG
```

2️⃣ **Thread pool issues?** Try reducing `thread_pool_size` to 5.

3️⃣ **Need to clear Redis?**

```bash
redis-cli FLUSHDB
```

## 🤝 Contributing
Pull requests are welcome! If you find bugs or have feature ideas, feel free to open an issue.
