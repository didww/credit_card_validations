module CreditCardValidations
  module CardRules
    ########  most used brands #########


    VISA = [
        {length: [16], prefixes: ['4']}
    ]
    MASTERCARD = [
        {length: [16], prefixes: ['51', '52', '53', '54', '55']}
    ]
    ######## other brands ########
    AMEX = [
        {length: [15], prefixes: ['34', '37']}
    ]

    DINERS = [
        {length: [14], prefixes: ['300', '301', '302', '303', '304', '305', '36']},
    ]

    #There are Diners Club (North America) cards that begin with 5. These are a joint venture between Diners Club and MasterCard, and are processed like a MasterCard
    # will be removed in next major version

    DINERS_US = [
        {length: [16], prefixes: ['54', '55']}
    ]

    DISCOVER = [
        {length: [16], prefixes: ['6011', '644', '645', '646', '647', '648',
                                '649', '65']}
    ]

    JCB = [
        {length: [16], prefixes: ['3528', '3529', '353', '354', '355', '356', '357', '358']}
    ]


    LASER = [
        {length: [16, 17, 18, 19], prefixes: ['6304', '6706', '6771', '6709']}
    ]

    MAESTRO = [
        {length: [12, 13, 14, 15, 16, 17, 18, 19], prefixes: ['5018', '5020', '5038', '6304', '6759', '6761', '6762','6763', '6764', '6765', '6766']}
    ]

    SOLO = [
        {length: [16, 18, 19], prefixes: ['6334', '6767']}
    ]
    # Luhn validation are skipped for union pay cards becouse they have unknown generation algoritm 
    UNIONPAY = [
        {length: [16, 17, 18, 19], prefixes: ['622', '624', '625', '626', '628'], skip_validation: true}
    ]

    DANKROT = [
       {length: [16], prefixes: ['5019']}
    ]


  end
end
