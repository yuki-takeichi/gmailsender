require 'connection_pool'
require 'csv'
require 'gmail'
require 'httpclient'
require 'mail-iso-2022-jp'
require 'nkf'
require 'parallel'
require 'retryable'
require 'yaml'

GOOGLE_OAUTH2_URL = 'https://accounts.google.com/o/oauth2/token'
CONFIG_YAML_PATH = './config.yaml'

def log(str)
  puts str
end

def refresh_access_token(query)
  client = HTTPClient.new
  response = client.post(GOOGLE_OAUTH2_URL, query)
  res = JSON.parse(response.body)
  access_token = res['access_token']
  raise res if access_token.nil?
  return access_token
end

config = YAML.load_file(CONFIG_YAML_PATH)
from_name   = config['from_name']
subject     = config['subject']
tmpl_path   = config['tmpl_path']
csv_path    = config['csv_path']
gmail_addr  = config['gmail_addr']
gmail_opts  = config['gmail_opts']
oauth2      = gmail_opts['oauth2']

tmpl = File.open(tmpl_path) {|f| f.read }
mails = CSV.read(csv_path).map do |row|
  to   = row[0]
  strs = row[1..-1]
  Mail.new(:charset => 'ISO-2022-JP') do
    from    '%s <%s>' % [from_name, gmail_addr]
    to      to
    subject subject
    body    tmpl % strs
  end
end

access_token = refresh_access_token(oauth2)
size = Parallel.processor_count
connection_pool = ConnectionPool.new(size: size, timeout: 5.0) do
  Gmail.connect!(:xoauth2, gmail_addr, access_token)
end

Parallel.each(mails) do |mail|
  connection_pool.with do |gmail|
    Retryable.retryable(tries: 10) do
      gmail.deliver!(mail)
      log '%s done' % mail.to
    end
  end
end

connection_pool.shutdown {|gmail| gmail.logout }

log 'finished'
