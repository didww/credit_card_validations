require_relative 'test_helper'

describe CreditCardValidations::Factory do

  it 'should generate random brand' do
    number = CreditCardValidations::Factory.random
    expect(CreditCardValidations::Detector.new(number).valid?).must_equal true
  end

  CreditCardValidations::Detector.brands.keys.sort.each do |key|
    describe "#{key}" do
      it "should generate valid #{key}" do
        number = CreditCardValidations::Factory.random(key)
        expect(CreditCardValidations::Detector.new(number).valid?(key)).must_equal true
      end
    end
  end

  describe '.random_card' do
    plugin_brands = Dir[File.expand_path('../lib/credit_card_validations/plugins/*.rb', __dir__)]
                      .map { |path| File.basename(path, '.rb').to_sym }.sort

    # Loading a plugin defines a predicate on Detector that reload! alone does
    # not undo — only delete_brand does. Wipe every brand, then reload.
    after do
      CreditCardValidations::Detector.brands.keys.each do |key|
        CreditCardValidations::Detector.delete_brand(key)
      end
      CreditCardValidations.reload!
    end

    (CreditCardValidations::Detector.brands.keys.sort + plugin_brands).each do |brand|
      it "builds a valid card for #{brand}" do
        load "credit_card_validations/plugins/#{brand}.rb" if plugin_brands.include?(brand)
        size = CreditCardValidations::Detector.brands.dig(brand, :options, :code, :size)

        if size.nil?
          # Detector.valid_cvv? raises for a brand with no :code, so no CVV
          # could make such a card valid — random_card must say so up front.
          error = expect { CreditCardValidations::Factory.random_card(brand) }
                    .must_raise CreditCardValidations::Error
          expect(error.message).must_match(/no :code option/)
        else
          card = CreditCardValidations::Factory.random_card(brand)
          expect(card).must_be_instance_of CreditCardValidations::Card
          expect(card.brand).must_equal brand
          expect(card.verification_value.length).must_equal size
          expect(card.expired?).must_equal false
          expect(card.valid?).must_equal true
        end
      end
    end

    it 'picks a random brand when none is given' do
      card = CreditCardValidations::Factory.random_card
      expect(card.valid?).must_equal true
    end

    it 'raises on an unsupported brand' do
      expect { CreditCardValidations::Factory.random_card(:nope) }
        .must_raise CreditCardValidations::Error
    end
  end
end