// Copyright (c) 2020-present, Rover Labs, Inc. All rights reserved.
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Rover.
//
// This copyright notice shall be included in all copies or substantial portions of
// the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@testable import JudoSDK
import XCTest

class StringInterpolationTests: XCTestCase {


    // MARK: - No Interpolation
    func test_evaluatingExpressions_withNoInterpolation_returnsOriginalString() throws {
        let sut = makeSUT(nonInterpolatedString())
        XCTAssertEqual(sut, nonInterpolatedString())
    }

    func test_evaluatingExpressions_givenDataURLParametersUserInfoAndNoInterpolation_returnsOriginalString() throws {
        let data = ["page":2]

        let urlParameters = constructURLParameters(with: ["key2": "value2"])

        let userInfo = constructUserInfo(with: ["userid": "54321"])

        let sut = makeSUT(nonInterpolatedString(), data: data, urlParameters: urlParameters, userInfo: userInfo)
        XCTAssertEqual(sut, nonInterpolatedString())
    }

    func test_evaluatingExpressions_incompleteInterpolation_returnsOriginalString() throws {
        let userInfo = constructUserInfo(with: ["userid": "54321"])

        let sut = makeSUT("{{user.userid", userInfo: userInfo)
        XCTAssertEqual(sut, "{{user.userid")
    }

    // MARK: - Returning Nil
    func test_evalutingExpression_withInterpolatingNoUserInfo_returnsNil() throws {
        returnsNilWhenUnableToInterpolate("{{user.userID}}")
    }

    func test_evalutingExpression_withInterpolatingNoURLParameters_returnsNil() throws {
        returnsNilWhenUnableToInterpolate("{{url.page}}")
    }

    func test_evaluatingExpressions_withInterpolatingNoData_returnsNil() throws {
        returnsNilWhenUnableToInterpolate("{{data.count}}")
    }

    func test_evaluatingExpressions_incorrectInterpolationWithTwoValues_returnsNil() throws {
        let userInfo = constructUserInfo(with: ["userid": "54321", "name": "mike"])
        returnsNilWhenUnableToInterpolate("{{user.userid user.name}}", userInfo: userInfo)
    }

    // MARK: - Straight Interpolation (no helpers)
    func test_evaluatingExpressions_withInterpolationForUserInfo_returnsExpectedString() throws {
        let userInfo = constructUserInfo(with: ["name":"George"])

        let sut = makeSUT("{{user.name}}", userInfo: userInfo)
        XCTAssertEqual(sut, "George")
    }

    func test_evaluatingExpressions_withInterpolationForURLParameters_returnsExpectedString() throws {
        let urlParameters = constructURLParameters(with: ["page":"three"])

        let sut = makeSUT("{{url.page}}", urlParameters: urlParameters)
        XCTAssertEqual(sut, "three")
    }

    func test_evaluatingExpressions_withInterpolationForData_returnsExpectedString() throws {

        let sut = makeSUT("{{data.age}}", data: ["age":"Twenty"])
        XCTAssertEqual(sut, "Twenty")
    }

    func test_evaluatingExpressions_withMultipleInterpolations_returnsExpectedString() throws {
        let data = ["page": 2]
        let urlParameters = constructURLParameters(with: ["key2": "value2"])
        let userInfo = constructUserInfo(with: ["userid": "54321"])

        let string = "{{data.page}} {{url.key2}} {{user.userid}}"

        let sut = makeSUT(string, data: data, urlParameters: urlParameters, userInfo: userInfo)
        XCTAssertEqual(sut, "2 value2 54321")
    }

    func test_evaluatingExpressions_dataWithDifferentNumberTypes_returnsExpectedString() throws {
        let data = ["int": 2, "negInt": -4, "double": 2.34, "negDouble": -55.7]
        let string = "{{data.int}} {{data.negInt}} {{data.double}} {{data.negDouble}}"

        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "2 -4 2 -56")
    }

    // MARK: - Lowercase helper
    func test_evaluatingExpressions_lowercaseString_returnsExpectedString() throws {
        let sut = makeSUT("{{lowercase \"UPPERCASED\"}}")
        XCTAssertEqual(sut, "uppercased")
    }

    func test_evaluatingExpressions_lowercase_returnsExpectedString() throws {
        let data = ["name": "AN UPPERCASE NAME"]
        let string = "{{lowercase data.name}}"

        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "an uppercase name")
    }

    func test_evaluatingExpressions_lowercase_invalidNumberOfArguments_returnsNil() throws {
        returnsNilWithIncorrectNumberOfArguments("lowercase", expectedArguments: 2)
    }

    // MARK: - Uppercase helper
    func test_evaluatingExpressions_uppercaseString_returnsExpectedString() throws {
        let sut = makeSUT("{{uppercase \"lowercased\"}}")
        XCTAssertEqual(sut, "LOWERCASED")
    }

    func test_evaluatingExpressions_uppercase_returnsExpectedString() throws {
        let urlParameters = constructURLParameters(with: ["info": "a lowercase name"])
        let string = "{{uppercase url.info}}"

        let sut = makeSUT(string, urlParameters: urlParameters)
        XCTAssertEqual(sut, "A LOWERCASE NAME")
    }

    func test_evaluatingExpressions_uppercase_invalidNumberOfArguments_returnsNil() throws {
        returnsNilWithIncorrectNumberOfArguments("uppercase", expectedArguments: 2)
    }

    // MARK: - Replace helper
    func test_evaluatingExpressions_replaceString_returnsExpectedString() throws {
        let sut = makeSUT("{{replace \"lowercased\" \"lower\" \"upper\"}}")
        XCTAssertEqual(sut, "uppercased")
    }
    
    func test_evaluatingExpression_replaceMultipleWords_returnsExpectedString() throws {
          let sut = makeSUT("{{replace \"jack be nimble\" \"be nimble\" \"is amazing\"}}")
          XCTAssertEqual(sut, "jack is amazing")
      }

    func test_evaluatingExpressions_replaces_returnsExpectedString() throws {
        let userInfo = constructUserInfo(with: ["message": "You should be good"])

        let string = "{{replace user.message \"should\" \"must\"}}"

        let sut = makeSUT(string, userInfo: userInfo)
        XCTAssertEqual(sut, "You must be good")
    }

    func test_evaluatingExpressions_replace_notInString_returnsInitialString() throws {
        let data = ["name": "mike"]

        let sut = makeSUT("{{replace data.name \"M\" \"P\"}}", data: data)
        XCTAssertEqual(sut, "mike")
    }
    
    func test_evaluatingExpressions_replace_thirdArgumentWithoutQuotes_returnsNil() throws {
        returnsNilWhenUnableToInterpolate("{{replace \"lowercased\" lower \"upper\"}}")
     }

     func test_evaluatingExpressions_replace_fourthArgumentWithoutQuotes_returnsNil() throws {
         returnsNilWhenUnableToInterpolate("{{replace \"a fox runs\" \"fox\" dog}}")
     }

     func test_evaluatingExpressions_replace_ThirdFourthArgumentsWithoutQuotes_returnsNil() throws {
         returnsNilWhenUnableToInterpolate("{{replace \"a fox runs\" fox dog}}")
     }

    func test_evaluatingExpressions_replace_invalidNumberOfArguments_returnsNil() throws {
        returnsNilWithIncorrectNumberOfArguments("replace", expectedArguments: 4)
    }
    
    func test_evaluatingExpressions_replace_compound_returnsExpectString() throws {
        let sut = makeSUT("{{ replace (dropLast (dropFirst \"mr. jack reacher\" 4) 8) \"jack\" \"mike\" }}")
        XCTAssertEqual(sut, "mike")
    }

    // MARK: - DateFormat helper
    func test_evaluatingExpressions_dateString_returnsExpectedString() throws {
        let sut = makeSUT("{{dateFormat \"2022-02-01 19:46:31+0000\" \"EEEE, d\"}}")
        XCTAssertEqual(sut, "Tuesday, 1")
    }

    func test_evaluatingExpressions_dateFormat_returnsExpectedString() throws {
        let timeString = "2022-02-01T19:46:31+0000"
        let data = ["date": timeString]
        let urlParameters = constructURLParameters(with: ["time": timeString])
        let userInfo = constructUserInfo(with: ["day": timeString])

        let string = "{{dateFormat data.date \"yyyy-MM-dd\"}}, {{dateFormat url.time \"HH:mm:ss\"}}. {{dateFormat user.day \"EEEE, MMM d, yyyy\"}}"

        let sut = makeSUT(string, data: data, urlParameters: urlParameters, userInfo: userInfo)
        
        let dateFormatter = ISO8601DateFormatter()
        let resultDate = dateFormatter.date(from: timeString)
        
        let resultFormatter = DateFormatter()
        resultFormatter.timeZone = TimeZone.current
        resultFormatter.dateFormat = "yyyy-MM-dd, HH:mm:ss. EEEE, MMM d, yyyy"
        let expectedResult = resultFormatter.string(from: resultDate!)
        
        XCTAssertEqual(sut, expectedResult)
    }
    
    func test_evaluatingExpressions_timeZonetimeFormat_returnsExpectedString() throws {
        let timeString = "2022-02-01T19:46:31+0700"
        let data = ["time": timeString]

        let string = "{{dateFormat data.time \"HH:mm:ss\"}}"

        let sut = makeSUT(string, data: data)
        
        let dateFormatter = ISO8601DateFormatter()
        let resultDate = dateFormatter.date(from: timeString)
        
        let resultFormatter = DateFormatter()
        resultFormatter.timeZone = TimeZone.current
        resultFormatter.dateFormat = "HH:mm:ss"
        let expectedResult = resultFormatter.string(from: resultDate!)
        
        XCTAssertEqual(sut, expectedResult)
    }

    // Added to cover the legacy usecase of date. This test should be removed once we stop
    // supporting the helper date and move to dateFormat exclusively.
    func test_evaluatingExpressions_date_returnsExpectedString() throws {
        let timeString = "2022-02-01T19:46:31+0000"
        let data = ["date": timeString]
        let urlParameters = constructURLParameters(with: ["time": timeString])
        let userInfo = constructUserInfo(with: ["day": timeString])

        let string = "{{date data.date \"yyyy-MM-dd\"}}, {{date url.time \"HH:mm:ss\"}}. {{date user.day \"EEEE, MMM d, yyyy\"}}"

        let sut = makeSUT(string, data: data, urlParameters: urlParameters, userInfo: userInfo)
        
        let dateFormatter = ISO8601DateFormatter()
        let resultDate = dateFormatter.date(from: timeString)
        
        let resultFormatter = DateFormatter()
        resultFormatter.timeZone = TimeZone.current
        resultFormatter.dateFormat = "yyyy-MM-dd, HH:mm:ss. EEEE, MMM d, yyyy"
        let expectedResult = resultFormatter.string(from: resultDate!)
        
        XCTAssertEqual(sut, expectedResult)
    }

    func test_evaluatingExpressions_dateFormat_invalidNumberOfArguments_returnsNil() throws {
        returnsNilWithIncorrectNumberOfArguments("dateFormat", expectedArguments: 3)
    }

    func test_evaluatingExpressions_dateFormat_returnsNil() throws {
        let data = ["date": "NOT A DATE!"]
        returnsNilWhenUnableToInterpolate("{{dateFormat data.date yyyy-MM-dd}}", data: data)
    }

    func test_evaluatingExpressions_dateFormat_invalidDateFormat_returnsNil() throws {
        let data = ["date" : "2022-02-01T19:46:31+0000"]
        returnsNilWhenUnableToInterpolate("{{dateFormat data.date yyyy-MM}}", data: data)
    }

    // MARK: - DropsFirst helper
    func test_evaluatingExpressions_dropFirstString_returnsExpectedString() throws {
        let sut = makeSUT("{{dropFirst \"Boom! Kapow!\" 6}}")
        XCTAssertEqual(sut, "Kapow!")
    }

    func test_evaluatingExpressions_dropFirst_returnsExpectedString() throws {
        let data = ["name": "Mr. Hulk Hogan"]
        let string = "{{dropFirst data.name 4}}"

        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "Hulk Hogan")
    }

    func test_evaluatingExpressions_dropFirst_invalidNumberOfArguments_returnsNil() throws {
        returnsNilWithIncorrectNumberOfArguments("dropFirst", expectedArguments: 3)
    }

    func test_evaluatingExpressions_dropFirst_nonInteger_returnsNil() throws {
        returnsNilWhenAnIntegerArgumentIsMissing("dropFirst")
    }

    // MARK: - DropsLast helper
    func test_evaluatingExpressions_dropLastString_returnsExpectedString() throws {
        let sut = makeSUT("{{dropLast \"Boom! Kapow!\" 7}}")
        XCTAssertEqual(sut, "Boom!")
    }

    func test_evaluatingExpressions_dropLast_returnsExpectedString() throws {
        let urlParameters = constructURLParameters(with: ["alphabet": "abcdefghijklmnopqrstuvwxyz"])
        let string = "{{dropLast url.alphabet 20}}"

        let sut = makeSUT(string, urlParameters: urlParameters)
        XCTAssertEqual(sut, "abcdef")
    }

    func test_evaluatingExpressions_dropLast_invalidNumberOfArguments_returnsNil() throws {
        returnsNilWithIncorrectNumberOfArguments("dropLast", expectedArguments: 3)
    }

    func test_evaluatingExpressions_dropLast_nonInteger_returnsNil() throws {
        returnsNilWhenAnIntegerArgumentIsMissing("dropLast")
    }

    // MARK: - Prefix helper
    func test_evaluatingExpressions_prefixString_returnsExpectedString() throws {
        let sut = makeSUT("{{prefix \"Stand by me!\" 8}}")
        XCTAssertEqual(sut, "Stand by")
    }

    func test_evaluatingExpressions_prefix_returnsExpectedString() throws {
        let userInfo = constructUserInfo(with: ["title":"Welcome to the jungle"])
        let string = "{{prefix user.title 7}}"

        let sut = makeSUT(string, userInfo: userInfo)
        XCTAssertEqual(sut, "Welcome")
    }

    func test_evaluatingExpressions_prefix_invalidNumberOfArguments_returnsNil() throws {
        returnsNilWithIncorrectNumberOfArguments("prefix", expectedArguments: 3)
    }

    func test_evaluatingExpressions_prefix_nonInteger_returnsNil() throws {
        returnsNilWhenAnIntegerArgumentIsMissing("prefix")
    }

    // MARK: - Suffix helper
    func test_evaluatingExpressions_suffixString_returnsExpectedString() throws {
        let sut = makeSUT("{{suffix \"Boom! Kapow!\" 6}}")
        XCTAssertEqual(sut, "Kapow!")
    }

    func test_evaluatingExpressions_suffix_returnsExpectedString() throws {
        let urlParameters = constructURLParameters(with: ["alphabet": "abcdefghijklmnopqrstuvwxyz"])
        let string = "{{suffix url.alphabet 4}}"

        let sut = makeSUT(string, urlParameters: urlParameters)
        XCTAssertEqual(sut, "wxyz")
    }

    func test_evaluatingExpressions_suffix_invalidNumberOfArguments_returnsNil() throws {
        returnsNilWithIncorrectNumberOfArguments("suffix", expectedArguments: 3)
    }

    func test_evaluatingExpressions_suffix_nonInteger_returnsNil() throws {
        returnsNilWhenAnIntegerArgumentIsMissing("suffix")
    }

    // MARK: - Nested helpers
    func test_exvaluationExpression_nestedHelpersString_returnsExpecteString() throws {
        let string = "{{ uppercase (suffix (dropFirst \"mr. jack reacher\" 4) 7) }}"
        let sut = makeSUT(string)
        XCTAssertEqual(sut, "REACHER")
    }

    func test_evaluatingExpressions_nestedHelpersMultiple_returnsExpectedString() throws {
        let data = ["name": "MR. JONATHON", "message": "Show me the way to go home!"]
        let string = "{{ lowercase (prefix (dropFirst data.name 4) 3) }} {{uppercase (dropLast data.message 6)}}"

        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "jon SHOW ME THE WAY TO GO")
    }

    func test_evaluatingExpressions_nestedHelpersMissingClosingParenthesis_returnsNil() throws {
        let string = "{{dropFirst (uppercase \"morrison\" 5}}"
        returnsNilWhenUnableToInterpolate(string)
    }

    func test_evaluatingExpressions_nestedHelpersMissingOpeningParenthesis_returnsNil() throws {
        let string = "{{dropFirst uppercase \"morrison\") 5}}"
        returnsNilWhenUnableToInterpolate(string)
    }

    // MARK: - NumberFormat helper
    func test_evaluatingExpressions_numberFormatStringLiteralNonNumber_returnsNil() throws {
        let string = "{{numberFormat \"Twenty\"}}"
        returnsNilWhenUnableToInterpolate(string)
    }

    func test_evaluatingExpressions_numberFormatNonNumber_returnsNil() throws {
        let userInfo = constructUserInfo(with: ["average": "NOT A NUMBER"])
        let string = "{{numberFormat user.average}}"
        returnsNilWhenUnableToInterpolate(string, userInfo: userInfo)
    }

    func test_evaluatingExpressions_numberFormat_invalidNumberOfArguments_returnsNil() throws {
        let invalidStrings = ["{{numberFormat }}", "{{numberFormat extra extra extra}}"]
        for string in invalidStrings {
            returnsNilWhenUnableToInterpolate(string)
        }
    }

    func test_evaluatingExpressions_numberFormatWithStringInt_returnsExpectedString() throws {
        let userInfo = constructUserInfo(with: ["balance": "23"])
        let string = "{{numberFormat user.balance}}"
        let sut = makeSUT(string, userInfo: userInfo)
        XCTAssertEqual(sut, "23")
    }

    func test_evaluatingExpressions_numberFormatWithStringDouble_returnsExpectedString() throws {
        let userInfo = constructUserInfo(with: ["balance": "23.55"])
        let string = "{{numberFormat user.balance}}"
        let sut = makeSUT(string, userInfo: userInfo)
        XCTAssertEqual(sut, "23.55")
    }

    func test_evaluatingExpressions_numberFormatWithStringLiteralInt_returnsExpectedString() throws {
        let string = "{{numberFormat \"568\"}}"
        let sut = makeSUT(string)
        XCTAssertEqual(sut, "568")
    }

    func test_evaluatingExpressions_numberFormatWithStringLiteralDouble_returnsExpectedString() throws {
        let string = "{{numberFormat \"123.456\"}}"
        let sut = makeSUT(string)
        XCTAssertEqual(sut, "123.456")
    }

    func test_evaluatingExpressions_numberFormatWithInt_returnsExpectedString() throws {
        let data = ["count": 30]
        let string = "{{numberFormat data.count}}"
        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "30")
    }

    func test_evaluatingExpressions_numberFormatWithDouble_returnsExpectedString() throws {
        let data = ["average": 12.3487]
        let string = "{{numberFormat data.average}}"
        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "12.349")
    }

    func test_evaluatingExpressions_numberFormatNone_returnsExpectedString() throws {
        let data = ["number": 42.5]
        let userInfo = constructUserInfo(with: ["average": "16.8"])
        let string = "{{numberFormat \"0.92\" \"none\"}} {{numberFormat data.number  \"none\"}} {{ numberFormat user.average  \"none\" }}"
        let sut = makeSUT(string, data: data, userInfo: userInfo)
        XCTAssertEqual(sut, "1 42 17")
    }

    func test_evaluatingExpressions_numberFormatDecimal_returnsExpectedString() throws {
        let data = ["number": 42.5]
        let userInfo = constructUserInfo(with: ["average": "16.81145"])
        let string = "{{numberFormat \"0.92\" \"decimal\"}} {{numberFormat data.number \"decimal\"}} {{ numberFormat user.average \"decimal\" }}"
        let sut = makeSUT(string, data: data, userInfo: userInfo)
        XCTAssertEqual(sut, "0.92 42.5 16.811")
    }

    func test_evaluatingExpressions_numberFormatNoStylePassed_returnsExpectedString() throws {
        let data = ["number": 42.5]
        let userInfo = constructUserInfo(with: ["average": "16.81145"])
        let string = "{{numberFormat \"0.92\"}} {{numberFormat data.number}} {{ numberFormat user.average }}"
        let sut = makeSUT(string, data: data, userInfo: userInfo)
        XCTAssertEqual(sut, "0.92 42.5 16.811")
    }

    func test_evaluatingExpressions_numberFormatInvalidStyle_returnsExpectedString() throws {
        let data = ["number": 42.5]
        let userInfo = constructUserInfo(with: ["average": "16.81145"])
        let string = "{{numberFormat \"0.92\" \"gibberish\"}} {{numberFormat data.number \"gibberish\"}} {{ numberFormat user.average gibberish}}"
        let sut = makeSUT(string, data: data, userInfo: userInfo)
        XCTAssertEqual(sut, "0.92 42.5 16.811")
    }

    func test_evaluatingExpression_numberFormatCurrency_returnsExpectedString() throws {
        let data = ["number": 42.5]
        let userInfo = constructUserInfo(with: ["average": "16.81145"])
        let string = "{{numberFormat \"0.92\" \"currency\"}} {{numberFormat data.number \"currency\"}} {{ numberFormat user.average \"currency\" }}"
        let sut = makeSUT(string, data: data, userInfo: userInfo)
        XCTAssertEqual(sut, "$0.92 $42.50 $16.81")
    }

    func test_evaluatingExpressions_numberFormatPercent_returnsExpectedString() throws {
        let data = ["number": 0.348]
        let userInfo = constructUserInfo(with: ["average": "0.1145"])
        let string = "{{numberFormat \"0.92\" \"percent\"}} {{numberFormat data.number \"percent\"}} {{ numberFormat user.average \"percent\" }}"
        let sut = makeSUT(string, data: data, userInfo: userInfo)
        XCTAssertEqual(sut, "92% 35% 11%")
    }

    func test_evaluatingExpressions_numberFormatWithNestedHelpers_returnsExpectedString() throws {
        let data = ["amount": "UK£123.45pence"]
        let string = "{{numberFormat (dropFirst (dropLast data.amount 5) 3) \"currency\"}}"
        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "$123.45")
    }
    
    func test_evaluatingExpressions_html_returnsExpectedString() throws {
        let data = ["body": "<div style=\"height: 300px\"><p><b>SAN JOSE</b></div>"]
        let string = "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0\"><div style=\"height: 300px\">{{data.body}}</div>"
        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0\"><div style=\"height: 300px\"><div style=\"height: 300px\"><p><b>SAN JOSE</b></div></div>")
    }
    
    // MARK: - New Line Specific Tests \n
    func test_evaluatingExpressions_newLineInDataSource_returnsExpectedString() throws {
        let data = ["newLine": "This has a \n in it"]
        let string = "{{data.newLine}}"
        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "This has a \n in it")
    }

     func test_evaluatingExpressions_newLineInStringLiteral_returnsExpectedString() throws {
         let string = "{{lowercase \"NEW LINE -> \n <- \"}}"
         let sut = makeSUT(string)
         XCTAssertEqual(sut, "new line -> \n <- ")
     }

     func test_evaluatingExpressions_unicodeNewLinesInDataSource_returnsExpectedString() throws {
         let data = ["body": "Mac insered new lines \u{2028} \u{2029}"]
         let string = "{{data.body}}"
         let sut = makeSUT(string, data: data)
         XCTAssertEqual(sut, "Mac insered new lines \u{2028} \u{2029}")
     }

     func test_evaluatingExpressions_unicodeNewLinesInStringLiteral_returnsExpectedString() throws {
         let string = "{{uppercase \"1st\u{2028}2nd\u{2029}3rd\"}}"
         let sut = makeSUT(string)
         XCTAssertEqual(sut, "1ST\u{2028}2ND\u{2029}3RD")
     }

     func test_evaluatingExpressions_newLinesMultipleHelpersFromDataSource_returnsExpectedString() throws {
         let data = ["body": "This is the first line\nand the second line"]
         let string = "{{dropFirst (uppercase (replace data.body \"line\" \"sentence\")) 8}}"
         let sut = makeSUT(string, data: data)
         XCTAssertEqual(sut, "THE FIRST SENTENCE\nAND THE SECOND SENTENCE")
     }

    // MARK: - Quotation Mark Specific Tests
    
    func test_evaluatingExpressions_additionalQuotationsRemain_returnsExpectedString() throws {
        let userInfo = constructUserInfo(with: ["username": "\"aperson\""])
        let string = "Username: {{user.username}}"
        let sut = makeSUT(string, userInfo: userInfo)
        XCTAssertEqual(sut, "Username: \"aperson\"")
    }
    
    func test_evaluatingExpressions_replace_valueMidSentenceHasSmartQuotes_returnsExpectedString() throws {
        let string = "{{replace \"My name is ‟Mike” smith\" \"Mike\" \"JAMES\"}}"
        let sut = makeSUT(string)
        XCTAssertEqual(sut, "My name is ‟JAMES” smith")
    }
    
    func test_evaluatingExpressions_removeFirstQuotationMarksInDataSource_returnsExpectedString() throws {
        let data = ["name": "\"Mike\""]
        let string = "{{dropFirst data.name 1}}"
        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "Mike\"")
    }
    
    func test_evaluatingExpressions_uppercaseWithQuotesInDataSource_returnsExpectedString() throws {
        let data = ["message": "Who you going to call? \"Ghostbusters\""]
        let string = "{{uppercase data.message}}"
        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "WHO YOU GOING TO CALL? \"GHOSTBUSTERS\"")
    }
    
    func test_evaluatingExpressions_lowercaseWithQuotesInDataSource_returnsExpectedString() throws {
        let data = ["phrase": "I AM \"HE-MAN\"!"]
        let string = "{{lowercase data.phrase}}"
        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "i am \"he-man\"!")
    }
    
    func test_evaluatingExpressions_dropFirstWithQuotesInDataSource_returnsExpectedString() throws {
        let data = ["phrase": "I AM \"HE-MAN\"!"]
        let string = "{{dropFirst data.phrase 5}}"
        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "\"HE-MAN\"!")
    }
    
    func test_evaluatingExpressions_dropLastWithQuotesInDataSource_returnsExpectedString() throws {
        let data = ["message": "Who you going to call? \"Ghostbusters\""]
        let string = "{{dropLast data.message 15}}"
        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "Who you going to call?")
    }
    
    func test_evaluatingExpressions_prefixWithQuotesInDataSource_returnsExpectedString() throws {
        let data = ["sentence": "Ancients spirits of \"evil\""]
        let string = "{{prefix data.sentence 7}}"
        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "Ancient")
    }
    
    func test_evaluatingExpressions_suffixWithQuotesInDataSource_returnsExpectedString() throws {
        let data = ["sentence": "Ancients spirits of \"evil\""]
        let string = "{{suffix data.sentence 6}}"
        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "\"evil\"")
    }
    
    func test_evaluatingExpressions_multipleExpressionsInStringWithQuotationMarks_returnsExpectedString() throws {
        let data = ["firstname": "Sally \"Anne\"", "lastname": "Smith \"(Duck)\""]
        let string = "{{uppercase data.firstname}} {{lowercase data.lastname}}"
        let sut = makeSUT(string, data: data)
        XCTAssertEqual(sut, "SALLY \"ANNE\" smith \"(duck)\"")
    }
    
    // MARK: - Failing Quotation Tests
    // The parsing should be updated so that these strings don't throw errors when passed.
    func test_evaluatingExpressions_replaceStringLiteralWithQuotations_throwsError() throws {
        let string = "{{replace \"My name is \"Mike\" smith\" \"Mike\" \"JAMES\"}}"
        returnsNilWhenUnableToInterpolate(string)
    }
    
    func test_evaluatingExpressions_uppercaseStringLiteralWithQuotations_throwsError() throws {
        let string = "{{uppercase \"Who you going to call? \"Ghostbusters\"!\"}}"
        returnsNilWhenUnableToInterpolate(string)
    }
    
    func test_evaluatingExpressions_lowercaseStringLiteralWithQuotations_throwsError() throws {
        let string = "{{lowercase \"\"MIKE\"\"}}"
        returnsNilWhenUnableToInterpolate(string)
    }
    
    func test_evaluatingExpressions_dropFirstStringLiteralWithQuotations_throwsError() throws {
        let string = "{{dropFirst \"My name is \"MIKE\"\" 3}}"
        returnsNilWhenUnableToInterpolate(string)
    }
    
    func test_evaluatingExpression_dropLastStringLiteralWithQuotations_throwsError() throws {
        let string = "{{dropLast \"My name is \"MIKE\" Schultz\" 1}}"
        returnsNilWhenUnableToInterpolate(string)
    }
    
    func test_evaluatingExpression_suffixStringLiteralWithQuotations_throwsError() throws {
        let string = "{{suffix \"My name is \"MIKE\" Schultz\" 7}}"
        returnsNilWhenUnableToInterpolate(string)
    }
    
    func test_evaluatingExpression_prefixStringLiteralWithQuotations_throwsError() throws {
        let string = "{{prefix \"\"MIKE\" Schultz\" 6}}"
        returnsNilWhenUnableToInterpolate(string)
    }
    
    func test_evaluatingExpressions_stringLiteralWithMultipleHelpersWithQuotationMarks_throwsError() throws {
        let string = "{{ uppercase (dropLast (dropFirst \"mr. \"Jack\" reacher\" 4) 8) }}"
        returnsNilWhenUnableToInterpolate(string)
    }
    
    func test_evaluatingExpressions_replaceQuotationMarksInStringLiteral_throwsError() throws {
        let string = "{{replace \"Welcome to the \"jungle\".\" \"\"\" \"::\"}}"
        returnsNilWhenUnableToInterpolate(string)
    }
    
    // The current implemention means that it is not possible to do a replace on quotation marks
    // that are contained within the data source string. This is a limitation of the current approach.
    func test_evaluatingExpression_replaceQuotationMarksInDataSource_throwsError() throws {
        let data = ["message": "Welcome to the \"jungle\"."]
        let string = "{{replace data.message \"\"\" \"::\"}}"
        returnsNilWhenUnableToInterpolate(string, data: data)
    }
    
    func test_evaluatingExpressions_multipleHelpersWithQuotationMarksInUserInfo_throwsError() throws {
        let userInfo = constructUserInfo(with: ["fullname":"mr. \"Jack\" reacher"])
        let string = "{{ uppercase (dropLast (dropFirst user.fullname 4) 8) }}"
        returnsNilWhenUnableToInterpolate(string, userInfo: userInfo)
    }
    
    func test_evelautingExpressions_multipleHelpersWithQuotationMarksInDataSource_throwsError() throws {
        let data = ["name": "\"Mike\" Jones"]
        let string = "{{dropLast (replace (uppercase data.name) \"MIKE\" \"JAMES\") 6}}"
        returnsNilWhenUnableToInterpolate(string, data: data)
    }
    
    func test_evaluatingExpressions_removeSurroundingQuotationMarksInDataSource_throwsError() throws {
        let data = ["name": "\"Mike\""]
        let string = "{{dropLast (dropFirst data.name 1) 1}} {{dropFirst (dropLast data.name 1) 1}}"
        returnsNilWhenUnableToInterpolate(string, data: data)
    }

    // MARK: - TestHelpers
    private func makeSUT(
        _ initialString: String,
        data: Any? = nil,
        urlParameters: [String: String] = .init(),
        userInfo: [String: Any] = .init()
    ) -> String? {
        initialString
            .evaluatingExpressions(
                data: data,
                urlParameters: urlParameters,
                userInfo: userInfo
            )
    }

    private func constructUserInfo(with parameters: [String: String]) -> [String: Any] {
        parameters.reduce(into: [:]) { userInfo, entry in
            userInfo[entry.key] = entry.value
        }
    }

    private func constructURLParameters(with parameters: [String: String]) -> [String: String] {
        parameters.reduce(into: [:]) { userInfo, entry in
            userInfo[entry.key] = entry.value
        }
    }

    private func unexpectedValueError() -> StringExpressionError {
        StringExpressionError.unexpectedValue
    }

    private func returnsNilWhenUnableToInterpolate(
        _ string: String,
        data: Any? = nil,
        urlParameters: [String: String] = .init(),
        userInfo: [String: Any] = .init(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT(string, data: data, urlParameters: urlParameters, userInfo: userInfo)
        XCTAssertNil(sut)
    }

    private func returnsNilWithIncorrectNumberOfArguments(
        _ helper: String,
        expectedArguments: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for count in 0...expectedArguments {
            if count == expectedArguments - 1 { // subtract 1 because the helper is the first argument
                continue
            }
            let extraArguments = Array(repeating: "extra", count: count).joined(separator: " ")
            let string = "{{\(helper) \(extraArguments)}}"
            returnsNilWhenUnableToInterpolate(
                string,
                file: file,
                line: line
            )
        }
    }

    private func returnsNilWhenAnIntegerArgumentIsMissing(
        _ string: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let data = ["name": "Mr. Smith"]
        returnsNilWhenUnableToInterpolate("{{\(string) data.name four}}", data: data, file: file, line: line)
    }

    private func nonInterpolatedString() -> String {
        "NON_INTERPOLATED_STRING"
    }
}
