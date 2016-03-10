# A command a Slack User issued
class Command < ApplicationRecord
  belongs_to :user

  before_validation :extract_cli_args, on: :create

  def run
    case command
    when "/jesus"
      jesus = Slackmos::Commands::Jesus.new
      title = "Let Jesus be your guide."
      postback_message(image_response(title, jesus.image))
    when "/dance"
      dance_party = Slackmos::Commands::DanceParty.new
      title = "Dance Party :dancer: :confetti_ball:"
      postback_message(image_response(title, dance_party.image))
    else
      Rails.logger.info "Unhandled command #{id}"
    end
  end

  def default_response
    { response_type: "in_channel" }
  end

  def image_response(title, uri)
    {
      response_type: "in_channel",
      attachments: [
        {
          title: title,
          color: "#ffffff",
          falbackk: "Unable to load that image, sorry.",
          image_url: uri
        }
      ]
    }
  end

  private

  def postback_message(message)
    response = client.post do |request|
      request.url callback_uri.path
      request.body = message.to_json
      request.headers["Content-Type"] = "application/json"
    end

    Rails.logger.info JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.info "Unable to post back to slack: '#{e.inspect}'"
  end

  def callback_uri
    @callback_uri ||= Addressable::URI.parse(response_url)
  end

  def client
    @client ||= begin
                  Faraday.new(url: "https://hooks.slack.com") do |faraday|
                    faraday.adapter Faraday.default_adapter
                  end
                end
  end

  def extract_cli_args
    self.subtask = "default"

    match = command_text.match(/-a ([-_\.0-9a-z]+)/)
    self.application = match[1] if match

    match = command_text.match(/^([-_\.0-9a-z]+)(?:\:([^\s]+))/)
    if match
      self.task    = match[1]
      self.subtask = match[2]
    end

    match = command_text.match(/^([-_\.0-9a-z]+)\s*/)
    self.task = match[1] if match
  end
end
