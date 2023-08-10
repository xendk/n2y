require "../spec_helper"
require "../../src/n2y/mapper"
require "../../src/n2y/ynab/transaction"
require "json"

include N2y

describe Mapper do
  it "raises on missing/bad booking date" do
    expect_raises(Exception, "No booking date in transaction") do
      Mapper.map(JSON.parse("{\"no\": \"Data\"}"), "1", "2")
    end

    expect_raises(Exception, "Invalid booking date: banana") do
      Mapper.map(JSON.parse("{\"bookingDate\": \"banana\"}"), "1", "2")
    end
  end

  it "raises on missing transaction id" do
    expect_raises(Exception, "No transaction id in transaction") do
      Mapper.map(JSON.parse("{\"bookingDate\": \"2023-06-15\"}"), "1", "2")
    end
  end

  it "raises on missing payee_name" do
    expect_raises(Exception, "No additionalInformation nor remittanceInformationUnstructured in transaction") do
      Mapper.map(JSON.parse("{\"bookingDate\": \"2023-06-15\", \"transactionId\": \"123\"}"), "1", "2")
    end
  end

  it "uses either additionalInformation nor remittanceInformationUnstructured for payee_name" do
    transaction = YNAB::Transaction.new(budget_id: "1", account_id: "2", date: "2023-06-15", amount: 150000, payee_name: "foo", import_id: "2023-06-1540bd001563085fc35165329ea1")
    Mapper.map(JSON.parse("{\"bookingDate\": \"2023-06-15\", \"transactionId\": \"123\", \"transactionAmount\": {\"amount\": \"150\"}, \"additionalInformation\": \"foo\"}"), "1", "2").should eq transaction

    transaction = YNAB::Transaction.new(budget_id: "1", account_id: "2", date: "2023-06-15", amount: 150000, payee_name: "foobar", import_id: "2023-06-1540bd001563085fc35165329ea1")
    Mapper.map(JSON.parse("{\"bookingDate\": \"2023-06-15\", \"transactionId\": \"123\", \"transactionAmount\": {\"amount\": \"150\"}, \"additionalInformation\": \"foo\", \"remittanceInformationUnstructured\": \"foobar\\nbaz\"}"), "1", "2").should eq transaction
  end

  it "raises on missing amount" do
    expect_raises(Exception, "No amount in transaction") do
      Mapper.map(JSON.parse("{\"bookingDate\": \"2023-06-15\", \"transactionId\": \"123\", \"additionalInformation\": \"foo\"}"), "1", "2")
    end
  end

  it "generates import_ids like YNAI did" do
    transaction = YNAB::Transaction.new(budget_id: "1", account_id: "2", date: "2023-07-04", amount: 150000, payee_name: "foo", import_id: "2023-07-043c74c1d1f9a1484dfc716e9565")
    Mapper.map(JSON.parse("{\"bookingDate\": \"2023-07-04\", \"transactionId\": \"ZmFsc2UsMTY4ODQyODgwMDAwMCwiMjAyMy0wNy0wNC0xMi40Mi4yMC4wMDUwMjkiCg\", \"transactionAmount\": {\"amount\": \"150\"}, \"additionalInformation\": \"foo\"}"), "1", "2").should eq transaction
  end

  it "generates different ids with seed" do
    transaction = YNAB::Transaction.new(budget_id: "1", account_id: "2", date: "2023-07-04", amount: 150000, payee_name: "foo", import_id: "2023-07-048825884a97bb130b748efcefa4")
    Mapper.map(JSON.parse("{\"bookingDate\": \"2023-07-04\", \"transactionId\": \"ZmFsc2UsMTY4ODQyODgwMDAwMCwiMjAyMy0wNy0wNC0xMi40Mi4yMC4wMDUwMjkiCg\", \"transactionAmount\": {\"amount\": \"150\"}, \"additionalInformation\": \"foo\"}"), "1", "2", "testing").should eq transaction
  end
end
