#!/usr/bin/env ruby
# coding:UTF-8

require 'open-uri'
require 'nokogiri'
require 'kindler'
# require 'date'
require 'pp'
require 'net/smtp'

$msmth_url = 'http://m.newsmth.net'

# get html
doc = Nokogiri::HTML(open($msmth_url).read) # m.newsmth.net is utf-8

top10_urls = Array.new
doc.css('body div#wraper div#m_main ul.slist li').each do |item|
  
  top10_urls << $msmth_url + item.children[1]['href'] if item['class'] != 'f'
end
# pp top10_urls
# get content
title = 'SMTH-Top10-' + Time.now.strftime('%Y-%m-%d')
book = Kindler::Book.new :title=>title,:author=>'ngn999',:output_dir => './books'

top10_urls.each_with_index do |url, idx|
  article = Nokogiri::HTML.parse(open(url).read) # m.newsmth.net is utf-8

  author = article.css('body div#wraper div#m_main ul.list li div.nav.hl div a')[1].content
  title = article.css('body div#wraper div#m_main ul.list li.f')[0].content
  time = article.css('body div#wraper div#m_main ul.list li div.nav.hl div a')[2].content
  article.css('body div#wraper div#m_main ul.list.sec li div.sp')[0].css("br").each { |node| node.replace("\n") }
  content = article.css('body div#wraper div#m_main ul.list.sec li div.sp')[0].text
  content = content.gsub(/\n/,"<br />")
  # pp author
  # pp title
  # pp time
  # pp content
  book.add_article ({
    :title    =>  title,
    :author   =>  author,
    :content  =>  content,
    :section  =>  idx.to_s})
end

# pp book

# generate mobi
book.generate

# send to kindle
filename = book.book_path
# Read a file and encode it into base64 format
filecontent = File.read(filename)
encodedcontent = [filecontent].pack("m")   # base64

marker = "AUNIQUEMARKER"

body =<<EOF
This is a test email to send an attachement.
EOF

# Define the main headers.
part1 =<<EOF
From: ngn999 <ngn999@126.com>
To: ngn998 <ngn998@gmail.com>
Subject: Sending Attachement
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=#{marker}
--#{marker}
EOF

# Define the message action
part2 =<<EOF
Content-Type: text/plain
Content-Transfer-Encoding:8bit

#{body}
--#{marker}
EOF

# Define the attachment section
part3 =<<EOF
Content-Type: application/octet-stream; name=\"#{File.basename(filename)}\"
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="#{filename}"

#{encodedcontent}
--#{marker}--
EOF

mailtext = part1 + part2 + part3

# Let's put our code in safe area
begin
  Net::SMTP.start('smtp.126.com', 
                  25, 
                  '126.com', 
                  'ngn999', 'xxxxxxxxx', :plain)  do |smtp|
    smtp.sendmail(mailtext, 'ngn999@126.com',
                  ['ngn998_78@kindle.cn'])
  end
rescue Exception => e  
  print "Exception occured: " + e  
end
