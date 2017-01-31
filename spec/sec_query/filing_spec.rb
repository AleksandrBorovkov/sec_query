# encoding: utf-8
include SecQuery
require 'spec_helper'

describe SecQuery::Filing do
  it '::uri_for_recent' do
    expect(SecQuery::Filing.uri_for_recent.to_s)
      .to eq('https://www.sec.gov/cgi-bin/browse-edgar?action=getcurrent&company&count=100&output=atom&owner=include&start=0')
  end

  it '::uri_for_cik' do
    expect(SecQuery::Filing.uri_for_cik('testing').to_s)
      .to eq('https://www.sec.gov/cgi-bin/browse-edgar?CIK=testing&action=getcompany&company&count=100&output=atom&owner=include&start=0')
  end

  describe '::filings_for_index' do
    let(:index) { File.read('./spec/support/idx/test.idx') }
    let(:filing1) { SecQuery::Filing.filings_for_index(index).first }

    it 'parses all of the filings' do
      expect(SecQuery::Filing.filings_for_index(index).count).to eq(4628)
    end

    it 'correctly parses out the link' do
      expect(filing1.link)
        .to eq('https://www.sec.gov/Archives/edgar/data/38723/0000038723-14-000001.txt')
    end

    it 'correctly parses out the cik' do
      expect(filing1.cik).to eq('38723')
    end

    it 'correctly parses out the term' do
      expect(filing1.term).to eq('424B3')
    end
  end

  describe '::recent', vcr: { cassette_name: 'recent' } do
    let(:filings) { [] }

    before(:each) do
      SecQuery::Filing.recent(start: 0, count: 10, limit: 10) do |filing|
        filings.push filing
      end
    end

    it 'should accept options' do
      expect(filings.count).to eq(10)
    end

    it 'should have filing attributes', vcr: { cassette_name: 'recent' } do
      filings.each do |filing|
        expect(filing.cik).to be_present
        expect(filing.title).to be_present
        expect(filing.summary).to be_present
        expect(filing.link).to be_present
        expect(filing.term).to be_present
        expect(filing.date).to be_present
        expect(filing.file_id).to be_present
      end
    end
  end

  describe "::find" do
    shared_examples_for "it found filings" do
      it "should return an array of filings" do
        filings.should be_kind_of(Array)
      end

      it "the filings should be valid" do
        is_valid_filing?(filings.first)
      end
    end

    let(:cik){"0000320193"}
    
    context "when querying by cik" do
      let(:filings){ SecQuery::Filing.find(cik) }

      describe "Filings", vcr: { cassette_name: "Steve Jobs"} do
        it_behaves_like "it found filings"
      end
    end
    
    context "when querying cik and by type param" do
      let(:filings){ SecQuery::Filing.find(cik, 0, 40, { type: "10-K" }) }

      describe "Filings", vcr: { cassette_name: "Steve Jobs"} do
        it_behaves_like "it found filings"

        it "should only return filings of type" do
          filings.first.term.should == "10-K"
        end
      end
    end
    
    describe '#content', vcr: { cassette_name: 'content' } do
      it 'returns content of the filing by requesting the link' do
        f = Filing.new(
          cik: 123,
          title: 'test filing title',
          summary: 'test filing',
          link: 'https://www.sec.gov/Archives/edgar/data/1572871/000114036114019536/0001140361-14-019536.txt',
          term: '4',
          date: Date.today,
          file_id: 1
        )
        expect(f.content).to eq(File.read('./spec/support/filings/filing.txt'))
      end
    end
  end
end
