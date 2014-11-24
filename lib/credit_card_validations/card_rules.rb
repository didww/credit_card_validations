module CreditCardValidations
  module CardRules
    ########  most used brands #########
    mattr_accessor :rules

    self.rules = {
        visa: [
            {length: [13, 16], prefixes: ['4']}
        ],
        mastercard: [
            {length: [16], prefixes: ['51', '52', '53', '54', '55']}
        ],
        ######## other brands ########
        amex: [
            {length: [15], prefixes: ['34', '37']}
        ],

        diners: [
            {length: [14], prefixes: ['300', '301', '302', '303', '304', '305', '36', '38']},
        ],

        #There are Diners Club (North America) cards that begin with 5. These are a joint venture between Diners Club and MasterCard, and are processed like a MasterCard
        # will be removed in next major version

        diners_us: [
            {length: [16], prefixes: ['54', '55']}
        ],

        discover: [
            {length: [16], prefixes: ['6011', '644', '645', '646', '647', '648',
                                      '649', '65']}
        ],

        jcb: [
            {length: [16], prefixes: ['3528', '3529', '353', '354', '355', '356', '357', '358', '1800', '2131']}
        ],


        laser: [
            {length: [16, 17, 18, 19], prefixes: ['6304', '6706', '6771']}
        ],

        solo: [
            {length: [16, 18, 19], prefixes: ['6334', '6767']}
        ],

        maestro: [
            {length: [12, 13, 14, 15, 16, 17, 18, 19], prefixes: ['5010', '5011', '5012', '5013', '5014', '5015', '5016', '5017', '5018',
                                                                  '502', '503', '504', '505', '506', '507', '508',
                                                                  '6012', '6013', '6014', '6015', '6016', '6017', '6018', '6019',
                                                                  '602', '603', '604', '605', '606',
                                                                  '677', '675', '674', '673', '672', '671', '670',
                                                                  '6760', '6761', '6762', '6763', '6764', '6765', '6766', '6768', '6769'
            ]
            }
        ],

        # Luhn validation are skipped for union pay cards because they have unknown generation algoritm
        unionpay: [
            {length: [16, 17, 18, 19], prefixes: ['62'], skip_validation: true}
        ],

        dankrot: [
            {length: [16], prefixes: ['5019']}
        ]
    }
  end
end
