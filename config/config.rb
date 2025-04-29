BASEDIR = File.dirname(File.dirname(File.realpath(__FILE__)))
ENV['GOOGLE_APPLICATION_CREDENTIALS'] = "#{BASEDIR}/config/credentials.json"
