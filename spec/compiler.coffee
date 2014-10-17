if window?
  parser = require 'html2json'
else
  chai = require 'chai' unless chai
  parser = require '../lib/compiler'

{expect, assert} = chai


parse = (title, sources, expectation, pending) ->
  itFn = if pending then xit else it

  if !(sources instanceof Array)
    sources = [sources]

  num = sources.length

  sources.forEach (source, i) ->

    describe "#{title} - #{i + 1}", ->
      result = null

      itFn 'ok ✓', ->
        result = parser.parse source
        expect(result).to.be.an 'array'

      if expectation
        itFn 'commands ✓', ->
          expect(result).to.eql expectation


# Helper function for expecting errors to be thrown when parsing.
#
# @param source [String] CCSS statements.
# @param message [String] This should be provided when a rule exists to catch
# invalid syntax, and omitted when an error is expected to be thrown by the PEG
# parser.
# @param pending [Boolean] Whether the spec should be treated as pending.
#
expectError = (source, message, pending) ->
  itFn = if pending then xit else it

  describe source, ->
    predicate = 'should throw an error'
    predicate = "#{predicate} with message: #{message}" if message?

    itFn predicate, ->
      exercise = -> parser.parse source
      expect(exercise).to.throw Error, message


describe 'HTML-to-JSON', ->

  it 'should provide a parse method', ->
    expect(parser.parse).to.be.a 'function'


  # Basics
  # ====================================================================

  describe "Basics", ->

    parse "lonely tag", [

          "<div></div>"

          "< div ></ div >"

          """
          <
          div
          ></
          div
          >
          """

        ],

        [
          {
            tag: 'div'
          }
        ]

    parse "nested tags", [

          "<section><div><div></div></div></section>"

          """
          <section>
            <div>
              <div></div>
            </div>
          </section>
          """

        ],

        [
          {
            tag: 'section'
            children: [
              {
                tag: 'div'
                children: [
                  {
                    tag: 'div'
                  }
                ]
              }
            ]
          }
        ]

    parse "nested tags with text", [

          """Hello <a href="https://thegrid.io">world <span class="name big">I am here </span>!</a>..."""

          """
            Hello <a href="https://thegrid.io">world <span class="name big">I am here </span>!</a>...
          """

          """
            <!-- <ignore> this! --> Hello <a href="https://thegrid.io">world <!-- <ignore> this! --><span class="name big"><!-- <ignore> this! -->I am here </span>!</a>...<!-- <ignore> this! -->
          """

        ],

        [
          "Hello "
          {
            tag: 'a'
            attributes:
              href: "https://thegrid.io"
            children: [
              "world "
              {
                tag: 'span'
                attributes:
                  class: ['name','big']
                children: [
                  "I am here "
                ]
              }
              "!"
            ]
          }
          "..."
        ]

    parse "html doc", [

          """
            <!DOCTYPE html>
            <html>
              <head>
                <meta charset="utf-8"/> <!-- self closing tag -->
                <title>Online version &raquo; PEG.js &ndash; Parser Generator for JavaScript</title>
              </head>
              <body>
                <h1>Hello World</h1>
              </body>
            </html>
          """,

          """
            <!DOCTYPE html>
            <html>
              <head>
                <meta charset="utf-8"> <!-- HTML5 empty tag -->
                <title>Online version &raquo; PEG.js &ndash; Parser Generator for JavaScript</title>
              </head>
              <body>
                <h1>Hello World</h1>
              </body>
            </html>
          """,

          """
            <!-- ignore -->
            <!DOCTYPE html>
            <!-- ignore -->
            <html>
              <!-- ignore -->
              <head>
                <!-- ignore -->
                <meta charset="utf-8"/>
                <!-- ignore -->
                <title>Online version &raquo; PEG.js &ndash; Parser Generator for JavaScript</title>
                <!-- ignore -->
              </head>
              <!-- ignore -->
              <body>
                <!-- ignore -->
                <h1>Hello World</h1>
                <!-- ignore -->
              </body>
              <!-- ignore -->
            </html>
            <!-- ignore -->
          """

        ],

        [
          "<!DOCTYPE html>"
          {
            tag: 'html'
            children: [
              {
                tag: 'head'
                children: [
                  {
                    tag: 'meta'
                    attributes:
                      charset: "utf-8"
                  }
                  {
                    tag: 'title'
                    children: [
                      "Online version &raquo; PEG.js &ndash; Parser Generator for JavaScript"
                    ]
                  }
                ]
              }
              {
                tag: 'body'
                children: [
                  {
                    tag: 'h1'
                    children: [
                      "Hello World"
                    ]
                  }
                ]
              }
            ]
          }
        ]



