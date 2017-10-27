require 'kramdown'

require 'kramdown/converter/base'

module Kramdown
  module Converter
    class Prismic < Base
      def convert(root)
        root.children.map { |child|
          convert_element(child)
        }.compact.flatten
      end

      def convert_element(element)
        send("convert_#{element.type}", element)
      end

      private

      def convert_header(element)
        {
          type: "heading#{element.options[:level]}",
          content: {
            text: element.options[:raw_text],
            spans: []
          }
        }
      end

      def convert_p(element)
        {
          type: "paragraph",
          content: extract_content(element)
        }
      end

      def convert_ol(element)
        convert_list(element, 'o-list-item')
      end

      def convert_ul(element)
        convert_list(element, 'list-item')
      end

      def convert_list(element, type)
        element.children.map do |child|
          convert_li(type, child)
        end
      end

      def convert_li(type, element)
        {
          type: type,
          content: extract_content(element)
        }
      end

      def extract_content(element, memo={text: '', spans: []})
        element.children.inject(memo) do |memo, child|
          send("extract_span_#{child.type}", child, memo)
          memo
        end
      end

      def insert_span(element, memo, span)
        span[:start] = memo[:text].size
        extract_content(element, memo)
        span[:end] = memo[:text].size
        memo[:spans] << span
        memo
      end

      def extract_span_text(element, memo)
        memo[:text] += element.value
        memo
      end

      def extract_span_a(element, memo)
        insert_span(element, memo, {
                      type: 'hyperlink',
                      data: {
                        url: element.attr["href"]
                      }
                    })
      end

      def extract_span_strong(element, memo)
        insert_span(element, memo, {
                      type: 'strong'
                    })
      end

      def extract_span_em(element, memo)
        insert_span(element, memo, {
                      type: 'em'
                    })
      end

      def extract_span_p(element, memo)
        extract_content(element, memo)
      end
    end
  end
end