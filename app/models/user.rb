class User < ApplicationRecord
	attr_accessor :remember_token, :activation_token

	before_save :downcase_email
	before_create :create_activation_digest

	validates :name, presence: true, length: {maximum: 50}
	VALID_EMAIL_REGEX = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
	validates :email, presence: true, length: {maximum: 255}, uniqueness: {case_sensitive: false}, format: {with: VALID_EMAIL_REGEX}

	has_secure_password
	validates :password, presence:true, length: {minimum: 6}

	class << self

		def activated_and_paginated_users(current_page)
			where(activated: true).paginate(page: current_page)
		end

		# Returns the hash digest of a given string
		def digest(string)
			cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
																										BCrypt::Engine.cost
			BCrypt::Password.create(string, cost: cost)
		end

		# Generates a new random token
		def new_token
			SecureRandom.urlsafe_base64
		end
	end

	# Stores a user in the database for persistent sessions.
	def remember
		self.remember_token = User.new_token
		update_attribute(:remember_digest, User.digest(remember_token))
	end

	# Checks whether the database stored digest matches the one generated from a given token.
	# Applied to password, remember and activation digests.
	def authenticated?(attribute, token)
		digest = send("#{attribute}_digest")
		return false if token.nil?
		BCrypt::Password.new(digest).is_password?(token)
	end

	def forget
		update_attribute(:remember_token, nil)
	end

	# Activates an account
	def activate
		update_columns(activated: true, activated_at: Time.zone.now)
	end

	# Sends account activation email
	def send_activation_email
		UserMailer.send_activation_email(self).deliver_now
	end

	private
		
		def downcase_email
			self.email.downcase!
		end

		def create_activation_digest
			self.activation_token = User.new_token
			update_attribute(:activation_digest, User.digest(activation_token))
		end

end
