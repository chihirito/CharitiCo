require 'net/http'
require 'uri'
require 'json'

class LearningProgressesController < ApplicationController
  before_action :authenticate_user!

  def index
    @word_data = fetch_random_word
    if @word_data.nil? || @word_data['word'].nil?
      flash[:alert] = "ランダムな単語の取得に失敗しました。再試行してください。"
      Rails.logger.debug("Redirecting to root_path due to fetch_random_word failure")
      redirect_to root_path
    else
      @options = generate_options(@word_data)
      Rails.logger.debug("Generated options: #{@options.inspect}")
    end
  end

  def new
    @learning_progress = current_user.learning_progresses.new
  end

  def create
    @learning_progress = current_user.learning_progresses.new(learning_progress_params)
    if @learning_progress.save
      redirect_to root_path, notice: '学習履歴が追加されました'
    else
      render :new
    end
  end

  
  def check
    @word = params[:word]
    @option = params[:option]
    @is_correct = correct_answer?(@word, @option)
    correct_option = fetch_correct_option(@word) # 正解の選択肢を取得
    current_user.increment!(:coins) if @is_correct # 正解した場合にコインを増やす
     binding.pry
    if @is_correct
      redirect_to correct_learning_progresses_path
    else
      render 'incorrect', locals: { correct_option: correct_option }
    end
  end

  private

  def fetch_random_word
    url = URI("https://wordsapiv1.p.rapidapi.com/words/?random=true")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["X-RapidAPI-Key"] = '9181eb53c2msh1ffb45d44a88647p16b21bjsnbaba426f557a'
    request["X-RapidAPI-Host"] = 'wordsapiv1.p.rapidapi.com'

    response = https.request(request)
    word_data = JSON.parse(response.body)
    Rails.logger.debug("Fetched word data: #{word_data}")
    word_data
  rescue StandardError => e
    Rails.logger.error("Error fetching random word: #{e.message}")
    nil
  end

  def generate_options(word_data)
    result = word_data['results']&.first
    if result
      synonyms = result['synonyms'] || []
      correct_option = synonyms.sample(1).first # 類語から正解の単語を1つ選ぶ
      other_words = fetch_random_words(3) # ランダムな単語を3つ取得
      options = other_words + [correct_option] # 正解の単語を選択肢に追加
      options.shuffle # 選択肢をシャッフルする
    else
      Rails.logger.debug("No result found in word data")
      ["ダミー1", "ダミー2", "ダミー3", "ダミー4"].shuffle
    end
  end

  def fetch_random_words(count)
    words = []
    count.times do
      word_data = fetch_random_word
      words << word_data['word'] if word_data && word_data['word']
    end
    words
  end

  def correct_answer?(word, option)
    encoded_word = URI.encode_www_form_component(word)
    url = URI("https://wordsapiv1.p.rapidapi.com/words/#{encoded_word}/synonyms")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["X-RapidAPI-Key"] = '9181eb53c2msh1ffb45d44a88647p16b21bjsnbaba426f557a'
    request["X-RapidAPI-Host"] = 'wordsapiv1.p.rapidapi.com'

    response = https.request(request)
    result = JSON.parse(response.body)
    synonyms = result['synonyms'] || []

    synonyms.include?(option)
  end

  def fetch_correct_option(word)
    encoded_word = URI.encode_www_form_component(word)
    url = URI("https://wordsapiv1.p.rapidapi.com/words/#{encoded_word}/synonyms")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request["X-RapidAPI-Key"] = '9181eb53c2msh1ffb45d44a88647p16b21bjsnbaba426f557a'
    request["X-RapidAPI-Host"] = 'wordsapiv1.p.rapidapi.com'

    response = https.request(request)
    result = JSON.parse(response.body)
    synonyms = result['synonyms'] || []
    synonyms.sample(1).first
  end

  def learning_progress_params
    params.require(:learning_progress).permit(:content, :progress)
  end
end
