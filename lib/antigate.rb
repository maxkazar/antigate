require "antigate/version"

module Antigate
  require 'net/http'
  require 'uri'
  require 'base64'

  def self.wrapper(key)
  	return Wrapper.new(key)
  end

  def self.balance(key)
  	wrapper = Wrapper.new(key)
  	return wrapper.balance
  end

  class Wrapper
  	attr_accessor :phrase, :regsense, :numeric, :calc, :min_len, :max_len

  	def initialize(key)
  		@key = key

  		@phrase = 0
  		@regsense = 0
  		@numeric = 0
  		@calc = 0
  		@min_len = 0
  		@max_len = 0
  	end

  	def recognize(file, ext)
  		added = nil
  		loop do
  			added = add(file, ext)
        next if added.nil?
  			if added.include? 'ERROR_NO_SLOT_AVAILABLE'
  				sleep(1)
  				next
  			else
  				break
  			end
  		end
  		if added.include? 'OK'
  			id = added.split('|')[1]
  			sleep(10)
  			status = nil
  			loop do
  				status = status(id)
          next if status.nil?
  				if status.include? 'CAPCHA_NOT_READY'
  					sleep(1)
  					next
  				else
  					break
  				end
  			end
  			return [id, status.split('|')[1]]
  		else
  			return added
  		end
  	end

  	def add(file, ext)
  		if file
  			params = {
  				'method' => 'base64',
  				'key' => @key,
  				'body' => Base64.encode64(file),
  				'ext' => ext,
  				'phrase' => @phrase,
  				'regsense' => @regsense,
  				'numeric' => @numeric,
  				'calc' => @calc,
  				'min_len' => @min_len,
  				'max_len' => @max_len
  			}
  			return Net::HTTP.post_form(URI('http://antigate.com/in.php'), params).body rescue nil
  		end
  	end

  	def status(id)
  		return Net::HTTP.get(URI("http://antigate.com/res.php?key=#{@key}&action=get&id=#{id}")) rescue nil
  	end

  	def bad(id)
  		return Net::HTTP.get(URI("http://antigate.com/res.php?key=#{@key}&action=reportbad&id=#{id}")) rescue nil
  	end

  	def balance
  		return Net::HTTP.get(URI("http://antigate.com/res.php?key=#{@key}&action=getbalance")) rescue nil
  	end
  end
end
