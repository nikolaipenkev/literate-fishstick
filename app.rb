require 'sinatra'
require 'redis'
require 'json'
require 'rufus-scheduler'
require 'uri'
require 'csv'
require_relative 'UltimateSEOCrawler'

class DashboardApp < Sinatra::Base
  set :port, 4567
  set :views, File.expand_path('./views', __dir__)
  set :public_folder, File.expand_path('./public', __dir__)

  def initialize
    super
    @redis = Redis.new
    @crawler = UltimateSEOCrawler.new('https://books.toscrape.com/', 2, 10)
    start_crawler_scheduler
  end

  def start_crawler_scheduler
    scheduler = Rufus::Scheduler.new
    scheduler.every '1m' do
      puts "[#{Time.now}] Starting crawler..."
      @crawler.run
    end
  end


  get '/' do
    @seo_data = fetch_seo_data
    erb :index
  end

  def fetch_seo_data
    seo_keys = @redis.keys('seo:*')
    seo_keys.map { |key| JSON.parse(@redis.get(key)) rescue {} }
  end

  get '/export' do
    send_file 'seo_report.csv', type: 'text/csv', disposition: 'attachment'
  end
end

DashboardApp.run!
