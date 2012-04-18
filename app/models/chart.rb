require 'base64'
class Chart < ActiveRecord::Base
    belongs_to :document
    before_save :generate_token

    def generate_token
        self.share_token ||= Base64.urlsafe_encode64(rand.to_s)
    end
end
