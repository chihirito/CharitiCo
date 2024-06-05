require 'net/http'
require 'uri'
require 'json'

class LearningProgressesController < ApplicationController
  before_action :authenticate_user!

  def index
    @word_data = fetch_random_word
    if @word_data.blank? || @word_data['word'].blank? || @word_data['results'].blank?
      redirect_to root_path
    else
      @options = generate_options(@word_data)
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
  
    Rails.logger.debug "Word: #{@word}, Option: #{@option}" # デバッグログの追加
  
    response = api_request("https://wordsapiv1.p.rapidapi.com/words/#{URI.encode_www_form_component(@word)}/synonyms")
    if response.is_a?(Net::HTTPSuccess)
      synonyms = JSON.parse(response.body)['synonyms'] || []
      Rails.logger.debug "Synonyms: #{synonyms}" # デバッグログの追加
      @is_correct = synonyms.include?(@option)
    else
      Rails.logger.error "API request failed with response: #{response.body}" # エラーログの追加
      @is_correct = false
    end
  
    correct_option = synonyms.sample || "No correct option found"
  
    current_user.increment!(:coins) if @is_correct
  
    Rails.logger.debug "is_correct: #{@is_correct}" # デバッグログの追加
  
    respond_to do |format|
      format.html do
        if @is_correct
          Rails.logger.debug "Rendering correct template" # デバッグログの追加
          render template: 'learning_progresses/correct'
        else
          flash[:correct_option] = correct_option
          Rails.logger.debug "Rendering incorrect template with correct_option: #{correct_option}" # デバッグログの追加
          render template: 'learning_progresses/incorrect'
        end
      end
      format.turbo_stream do
        if @is_correct
          Rails.logger.debug "Rendering correct turbo_stream template" # デバッグログの追加
          render template: 'learning_progresses/correct'
        else
          Rails.logger.debug "Rendering incorrect turbo_stream template with correct_option: #{correct_option}" # デバッグログの追加
          render template: 'learning_progresses/incorrect', locals: { correct_option: correct_option }
        end
      end
    end
  end
  
  

  private

  def fetch_random_word
    response = api_request("https://wordsapiv1.p.rapidapi.com/words/?random=true")
    return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

  end

  def generate_options(word_data)
    result = word_data.dig('results', 0)
      correct_option = result['synonyms'].sample
      other_words = Array.new(3) { fetch_random_word&.dig('word') }.compact
      (other_words + [correct_option]).shuffle
  end

  def fetch_correct_synonyms(word)
    response = api_request("https://wordsapiv1.p.rapidapi.com/words/#{URI.encode_www_form_component(word)}/synonyms")
    return JSON.parse(response.body).fetch('synonyms', [])
  end

  def api_request(url)
    uri = URI(url)
    request = Net::HTTP::Get.new(uri)
    request["X-RapidAPI-Key"] = '9181eb53c2msh1ffb45d44a88647p16b21bjsnbaba426f557a'
    request["X-RapidAPI-Host"] = 'wordsapiv1.p.rapidapi.com'

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  rescue StandardError => e
    Rails.logger.error("API request error: #{e.message}")
    nil
  end

  def learning_progress_params
    params.require(:learning_progress).permit(:content, :progress)
  end
end
