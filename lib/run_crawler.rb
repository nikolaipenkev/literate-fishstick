require_relative 'crawler'

# Start the crawler
crawler = Crawler.new('https://www.dev.to/', 2, 10)
crawler.run
