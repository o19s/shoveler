#! /usr/bin/env ruby
require 'rubygems'
require 'rsolr'
require 'faker'
require 'ruby-progressbar'

solr_url = 'http://localhost:8983/solr/hs'
docs = 50_000_001
page_size = 10_000

# create a fake document
# check the Faker gem docs for more fake data types:
# https://github.com/stympy/faker
def fakeDoc(id)
  doc = {}
  doc[:id] = id
  doc[:companyid] = preferValue(1, id, 6) || Faker::Number.number(2)
  # some docs should have last user reply-s, some should not
  doc[:lastUserReplyAt] = preferValue(Faker::Time.backward(30), id, 3)
  doc[:createdAt] = Faker::Time.backward 365
  return doc
end

# when we want to over-represent a certain value
# value: the value to use
# index: the current index value(used to test frequency)
# frequency: it's a reciprical so lower means more frequent
def preferValue(value, index, frequency = 3)
  index % frequency == 1 ? value : nil
end

def fakeDocPage(size, start_id)
  doc_page = []
  size.times do |i|
    doc_page << fakeDoc(start_id + i)
  end
  return doc_page
end

solr = RSolr.connect url: solr_url
solr.delete_by_query '*:*'
solr.commit
solr.optimize

pb = ProgressBar.create title: "Doc pages(#{page_size}/pg)", total: (docs/page_size) + 1, format: '%t |%B| %c/%C %R/sec %E'

# push doc pages to repo
(docs / page_size).times do |x|
  solr.add fakeDocPage(page_size, x * page_size)
  pb.increment
end
# grab any remainder docs
solr.add fakeDocPage(docs % page_size, (docs/page_size) * page_size)
solr.commit
pb.increment


