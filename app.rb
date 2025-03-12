require 'sinatra'
require 'redis'
require 'json'
require 'rufus-scheduler'
require 'uri'
require 'csv'
require 'sqlite3'
require_relative 'UltimateSEOCrawler'
require_relative 'database'

class DashboardApp < Sinatra::Base
  set :port, 4567
  set :views, File.expand_path('./views', __dir__)
  set :public_folder, File.expand_path('./public', __dir__)

  def initialize
    super
    @crawler = UltimateSEOCrawler.new('https://automationteststore.com/', 2, 100)
    start_crawler_scheduler
  end

  def start_crawler_scheduler
    scheduler = Rufus::Scheduler.new
    scheduler.every '1m' do
      puts "[#{Time.now}] Starting crawler..."
      @crawler.crawl
    end
  end

  get '/' do
    @seo_data = fetch_seo_data
    erb :index
  end

  def fetch_seo_data
    DB.execute("SELECT * FROM seo_data WHERE crawled = 1")
  end

  def generate_csv(file_path = "seo_report.csv")
    data = fetch_seo_data
    return false if data.empty?  # Exit if no data to export

    CSV.open(file_path, "w") do |csv|
      csv << ["URL", "Title", "Title Length", "Meta Description", "Meta Description Length",
              "H1", "H2", "H3", "Canonical", "Robots Meta", "Schema Present", "Missing ALT %",
              "Word Count", "Internal Links", "External Links", "Broken Links", "Load Time",
              "Page Size", "HTTPS", "Google Analytics Present", "Google Tag Manager Present"]

      data.each do |row|
        csv << [row["url"], row["title"], row["title_length"], row["meta_description"],
                row["meta_description_length"], row["h1"], row["h2"], row["h3"], row["canonical"],
                row["robots_meta"], row["schema_present"], row["missing_alt_percentage"],
                row["word_count"], row["internal_links"], row["external_links"], row["broken_links"],
                row["load_time"], row["page_size"], row["is_https"], row["has_google_analytics"],
                row["has_google_tag_manager"]]
      end
    end

    return true
  end

  get '/export' do
    file_path = File.expand_path("seo_report.csv", Dir.pwd)

    # Generate CSV before sending
    if generate_csv(file_path)
      send_file file_path, type: 'text/csv', disposition: 'attachment'
    else
      halt 404, "No data available to export"
    end
  end


  post '/crawl' do
    url = params[:url]

    # Ensure URL is valid
    if url.nil? || url.strip.empty? || !(url =~ /\A#{URI::regexp(%w[http https])}\z/)
      halt 400, "Invalid URL. Please enter a valid website URL."
    end

    # Start crawling in a background thread
    Thread.new {UltimateSEOCrawler.new(url, 2, 100).crawl}

    # Redirect back to the dashboard
    redirect '/'
  end

  get '/clear_db' do
    DB.execute("DELETE FROM seo_data") # Delete all rows
    DB.execute("VACUUM") # Optimize database size
    puts "🗑️ Database cleared!"

    redirect '/'
  end

  get '/seo_data.json' do
    content_type :json

    rows = DB.execute("SELECT * FROM seo_data WHERE crawled = 1")

    # Organize the data into a hash. For example, if you have multiple rows per stat,
    # you might aggregate them (here we simply sum them)
    seo_stats = {}
    rows.each do |row|
      stat = row["stat"]
      value = row["value"].to_f
      seo_stats[stat] ||= 0
      seo_stats[stat] += value
    end

    seo_stats.to_json
  end


end

DashboardApp.run!
