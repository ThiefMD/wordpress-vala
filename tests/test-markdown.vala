namespace Wordpress {

    public class MarkdownTests : Object {
        public static void register_tests () {
            Test.add_func ("/markdown/headings", test_headings);
            Test.add_func ("/markdown/paragraphs", test_paragraphs);
            Test.add_func ("/markdown/lists", test_lists);
            Test.add_func ("/markdown/nested-lists", test_nested_lists);
            Test.add_func ("/markdown/code-blocks", test_code_blocks);
            Test.add_func ("/markdown/code-block-language", test_code_block_language);
            Test.add_func ("/markdown/code-block-language-info-string", test_code_block_language_info_string);
            Test.add_func ("/markdown/title-edge-cases", test_title_edge_cases);
            Test.add_func ("/markdown/quotes", test_quotes);
            Test.add_func ("/markdown/nested-quotes-citations", test_nested_quotes_and_citations);
            Test.add_func ("/markdown/thematic-breaks", test_thematic_breaks);
            Test.add_func ("/markdown/html-blocks", test_html_blocks);
            Test.add_func ("/markdown/math-blocks", test_math_blocks);
            Test.add_func ("/markdown/inline-formatting", test_inline_formatting);
            Test.add_func ("/markdown/image-blocks", test_image_blocks);
            Test.add_func ("/markdown/reference-style", test_reference_style);
            Test.add_func ("/markdown/link-image-titles", test_link_and_image_titles);
            Test.add_func ("/markdown/footnotes", test_footnotes);
            Test.add_func ("/markdown/multiline-footnotes", test_multiline_footnotes);
            Test.add_func ("/markdown/setext-headings", test_setext_headings);
            Test.add_func ("/markdown/strikethrough", test_strikethrough);
            Test.add_func ("/markdown/task-lists", test_task_lists);
            Test.add_func ("/markdown/tables", test_tables);
            Test.add_func ("/markdown/table-alignment", test_table_alignment);
            Test.add_func ("/markdown/gallery", test_gallery);
            Test.add_func ("/markdown/escapes", test_escapes);
            Test.add_func ("/markdown/robustness", test_robustness);
            Test.add_func ("/markdown/bugfix-list-continuation", test_bug_fix_list_continuation);
            Test.add_func ("/markdown/malformed-title-syntax", test_malformed_title_syntax);
            Test.add_func ("/markdown/mixed-valid-and-malformed-titles", test_mixed_valid_and_malformed_titles);
            Test.add_func ("/markdown/mixed-valid-and-malformed-reference-titles", test_mixed_valid_and_malformed_reference_titles);
        }

        private static void expect_equal (string expected, string actual, string test_name) {
            if (expected != actual) {
                Test.message ("%s", test_name);
                Test.message ("Expected: [%s]", expected);
                Test.message ("Actual:   [%s]", actual);
                Test.fail ();
            }
        }

        private static void expect_true (bool actual, string test_name) {
            if (!actual) {
                Test.message ("%s", test_name);
                Test.fail ();
            }
        }

        private static void test_headings () {
            string md = "# Heading 1\n## Heading 2\n### Heading 3";
            string expected = "<!-- wp:heading {\"level\":1} -->\n<h1>Heading 1</h1>\n<!-- /wp:heading -->\n\n" +
                              "<!-- wp:heading {\"level\":2} -->\n<h2>Heading 2</h2>\n<!-- /wp:heading -->\n\n" +
                              "<!-- wp:heading {\"level\":3} -->\n<h3>Heading 3</h3>\n<!-- /wp:heading -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "Headings");
        }

        private static void test_paragraphs () {
            string md = "First paragraph.\n\nSecond paragraph.";
            string expected = "<!-- wp:paragraph -->\n<p>First paragraph.</p>\n<!-- /wp:paragraph -->\n\n" +
                              "<!-- wp:paragraph -->\n<p>Second paragraph.</p>\n<!-- /wp:paragraph -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "Paragraphs");
        }

        private static void test_lists () {
            string md = "* Item 1\n* Item 2";
            string expected = "<!-- wp:list {\"ordered\":false} -->\n<ul>\n<li>Item 1</li>\n<li>Item 2</li>\n</ul>\n<!-- /wp:list -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "Unordered List");

            md = "1. First\n2. Second";
            expected = "<!-- wp:list {\"ordered\":true} -->\n<ol>\n<li>First</li>\n<li>Second</li>\n</ol>\n<!-- /wp:list -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "Ordered List");
        }

        private static void test_nested_lists () {
            string md = "* Item 1\n  * Nested 1.1\n* Item 2";
            string expected = "<!-- wp:list {\"ordered\":false} -->\n<ul>\n<li>Item 1\n<ul>\n<li>Nested 1.1</li>\n</ul>\n</li>\n<li>Item 2</li>\n</ul>\n<!-- /wp:list -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "Nested List");
        }

        private static void test_code_blocks () {
            string md = "```\nvoid main() {\n    print(\"Hello\");\n}\n```";
            string expected = "<!-- wp:code -->\n<pre class=\"wp-block-code\"><code>void main() {\n    print(&quot;Hello&quot;);\n}\n</code></pre>\n<!-- /wp:code -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "Code Block");
        }

        private static void test_code_block_language () {
            string md = "```javascript\nconst snack = 42;\n```";
            string actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<code class=\"language-javascript\">"), "Code Block Language Class");
        }

        private static void test_code_block_language_info_string () {
            string md = "```python linenums=true\nprint('hi')\n```";
            string actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<code class=\"language-python\">"), "Code Block Language Uses First Token");
        }

        private static void test_quotes () {
            string md = "> A quote\n> with two lines";
            string expected = "<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\"><!-- wp:paragraph -->\n<p>A quote</p>\n<!-- /wp:paragraph -->\n<!-- wp:paragraph -->\n<p>with two lines</p>\n<!-- /wp:paragraph -->\n</blockquote>\n<!-- /wp:quote -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "Blockquote");
        }

        private static void test_nested_quotes_and_citations () {
            string md = "> Outer\n>> Inner\n> -- Author";
            string expected = "<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\"><!-- wp:paragraph -->\n<p>Outer</p>\n<!-- /wp:paragraph -->\n<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\"><!-- wp:paragraph -->\n<p>Inner</p>\n<!-- /wp:paragraph -->\n</blockquote>\n<!-- /wp:quote -->\n<cite>Author</cite></blockquote>\n<!-- /wp:quote -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "Nested Blockquote and Citation");
        }

        private static void test_thematic_breaks () {
            string md = "---\n***\n* * *";
            string expected = "<!-- wp:separator -->\n<hr class=\"wp-block-separator\"/>\n<!-- /wp:separator -->\n\n" +
                              "<!-- wp:separator -->\n<hr class=\"wp-block-separator\"/>\n<!-- /wp:separator -->\n\n" +
                              "<!-- wp:separator -->\n<hr class=\"wp-block-separator\"/>\n<!-- /wp:separator -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "Thematic Breaks");
        }

        private static void test_html_blocks () {
            string md = "<div>\n<span>Raw HTML</span>\n</div>";
            string expected = "<!-- wp:html -->\n<div>\n<!-- /wp:html -->\n\n" +
                              "<!-- wp:html -->\n<span>Raw HTML</span>\n<!-- /wp:html -->\n\n" +
                              "<!-- wp:html -->\n</div>\n<!-- /wp:html -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "HTML Blocks");
        }

        private static void test_math_blocks () {
            string md = "$$e = mc^2$$";
            string expected = "<!-- wp:latex {\"latex\":\"e = mc^2\"} -->\n<p class=\"wp-block-latex\">$e = mc^2$</p>\n<!-- /wp:latex -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "Math Block (Single Line)");

            md = "$$\na^2 + b^2 = c^2\n$$";
            expected = "<!-- wp:latex {\"latex\":\"a^2 + b^2 = c^2\"} -->\n<p class=\"wp-block-latex\">$a^2 + b^2 = c^2$</p>\n<!-- /wp:latex -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "Math Block (Multi-line)");
        }

        private static void test_inline_formatting () {
            string md = "Text with **bold**, *italic*, [link](https://example.com), and `code`.";
            string actual = MarkdownConverter.to_blocks (md);
            
            expect_true (actual.contains ("<strong>bold</strong>"), "Inline Bold");
            expect_true (actual.contains ("<em>italic</em>"), "Inline Italic");
            expect_true (actual.contains ("<a href=\"https://example.com\">link</a>"), "Inline Link");
            expect_true (actual.contains ("<code>code</code>"), "Inline Code");
        }

        private static void test_image_blocks () {
            string md = "![Alt text](https://example.com/image.png)";
            string expected = "<!-- wp:image -->\n<figure class=\"wp-block-image\"><img src=\"https://example.com/image.png\" alt=\"Alt text\"/></figure>\n<!-- /wp:image -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "Image Block");

            md = "Paragraph with ![Inline Image](https://example.com/inline.png)";
            string actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<!-- wp:paragraph -->"), "Inline image remains in paragraph");
            expect_true (actual.contains ("<img src=\"https://example.com/inline.png\" alt=\"Inline Image\" />"), "Inline image rendered as img tag");
        }

        private static void test_reference_style () {
            string md = "Check [this link][ref] and ![this image][img].\n\n[ref]: https://example.com\n[img]: https://example.com/img.png";
            string actual = MarkdownConverter.to_blocks (md);
            
            expect_true (actual.contains ("<a href=\"https://example.com\">this link</a>"), "Reference Link");
            expect_true (actual.contains ("<img src=\"https://example.com/img.png\" alt=\"this image\" />"), "Reference Image");
            expect_true (!actual.contains ("[ref]:"), "Reference definitions are consumed");

            md = "[collapsed][]\n\n[collapsed]: https://collapsed.com";
            actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<a href=\"https://collapsed.com\">collapsed</a>"), "Collapsed Reference Link");
        }

        private static void test_link_and_image_titles () {
            string md = "[site](https://example.com \"Example Site\") and ![pic](https://example.com/pic.png \"Picture Title\")";
            string actual = MarkdownConverter.to_blocks (md);

            expect_true (actual.contains ("<a href=\"https://example.com\" title=\"Example Site\">site</a>"), "Inline Link Title");
            expect_true (actual.contains ("<img src=\"https://example.com/pic.png\" alt=\"pic\" title=\"Picture Title\" />"), "Inline Image Title");

            md = "[ref link][ref] ![ref img][img]\n\n[ref]: https://example.com \"Reference Title\"\n[img]: https://example.com/pic.png \"Reference Image\"";
            actual = MarkdownConverter.to_blocks (md);

            expect_true (actual.contains ("<a href=\"https://example.com\" title=\"Reference Title\">ref link</a>"), "Reference Link Title");
            expect_true (actual.contains ("<img src=\"https://example.com/pic.png\" alt=\"ref img\" title=\"Reference Image\" />"), "Reference Image Title");

            md = "[single](https://example.com 'Single Title') and [paren](https://example.net (Paren Title))";
            actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<a href=\"https://example.com\" title=\"Single Title\">single</a>"), "Inline Link Single-Quoted Title");
            expect_true (actual.contains ("<a href=\"https://example.net\" title=\"Paren Title\">paren</a>"), "Inline Link Parenthesized Title");

            md = "![single img](https://example.com/a.png 'Single Img') and ![paren img](https://example.com/b.png (Paren Img))";
            actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<img src=\"https://example.com/a.png\" alt=\"single img\" title=\"Single Img\" />"), "Inline Image Single-Quoted Title");
            expect_true (actual.contains ("<img src=\"https://example.com/b.png\" alt=\"paren img\" title=\"Paren Img\" />"), "Inline Image Parenthesized Title");
        }

        private static void test_title_edge_cases () {
            string md = "[one](https://one.test 'First') [two](https://two.test (Second)) [three](https://three.test \"Third\")";
            string actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<a href=\"https://one.test\" title=\"First\">one</a>"), "Multiple Link Titles Single Quote");
            expect_true (actual.contains ("<a href=\"https://two.test\" title=\"Second\">two</a>"), "Multiple Link Titles Parenthesized");
            expect_true (actual.contains ("<a href=\"https://three.test\" title=\"Third\">three</a>"), "Multiple Link Titles Double Quote");

            md = "![Poster](https://img.test/poster.png 'Poster Title')";
            actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<img src=\"https://img.test/poster.png\" alt=\"Poster\" title=\"Poster Title\"/>"), "Block Image Single-Quoted Title");

            md = "[ref link][r1] ![ref image][r2]\n\n[r1]: https://ref-link.test 'Ref Link'\n[r2]: https://ref-image.test/img.png (Ref Image)";
            actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<a href=\"https://ref-link.test\" title=\"Ref Link\">ref link</a>"), "Reference Link Single-Quoted Title");
            expect_true (actual.contains ("<img src=\"https://ref-image.test/img.png\" alt=\"ref image\" title=\"Ref Image\" />"), "Reference Image Parenthesized Title");
        }

        private static void test_malformed_title_syntax () {
            string md = "[broken](https://example.com \"Missing end) and ![oops](https://img.test/a.png 'Missing end)";
            string actual = MarkdownConverter.to_blocks (md);

            expect_true (!actual.contains ("<a href=\"https://example.com\""), "Malformed Link Title Not Converted");
            expect_true (!actual.contains ("<img src=\"https://img.test/a.png\""), "Malformed Image Title Not Converted");
            expect_true (actual.contains ("[broken](https://example.com &quot;Missing end)"), "Malformed Link Left As Text");
            expect_true (actual.contains ("![oops](https://img.test/a.png &apos;Missing end)"), "Malformed Image Left As Text");
        }

        private static void test_mixed_valid_and_malformed_titles () {
            string md = "[good](https://good.test \"Good\") [bad](https://bad.test \"Missing) ![img](https://img.test/a.png 'Img Title')";
            string actual = MarkdownConverter.to_blocks (md);

            expect_true (actual.contains ("<a href=\"https://good.test\" title=\"Good\">good</a>"), "Valid Link Still Parses");
            expect_true (actual.contains ("<img src=\"https://img.test/a.png\" alt=\"img\" title=\"Img Title\" />"), "Valid Image Still Parses");
            expect_true (!actual.contains ("<a href=\"https://bad.test\""), "Malformed Link Not Converted");
            expect_true (actual.contains ("[bad](https://bad.test &quot;Missing)"), "Malformed Link Preserved As Text");
        }

        private static void test_mixed_valid_and_malformed_reference_titles () {
            string md = "[good][g] [bad][b] ![img][i]\n\n[g]: https://good-ref.test \"Good Ref\"\n[b]: https://bad-ref.test \"Missing\n[i]: https://img-ref.test/pic.png (Image Ref)";
            string actual = MarkdownConverter.to_blocks (md);

            expect_true (actual.contains ("<a href=\"https://good-ref.test\" title=\"Good Ref\">good</a>"), "Valid Reference Link Still Parses");
            expect_true (actual.contains ("<img src=\"https://img-ref.test/pic.png\" alt=\"img\" title=\"Image Ref\" />"), "Valid Reference Image Still Parses");
            expect_true (actual.contains ("<a href=\"https://bad-ref.test\">bad</a>"), "Malformed Reference Link Falls Back To URL Only");
            expect_true (!actual.contains ("<a href=\"https://bad-ref.test\" title="), "Malformed Reference Link Has No Title");
        }

        private static void test_footnotes () {
            string md = "Text with a footnote.[^1]\n\n[^1]: This is the footnote content.";
            string actual = MarkdownConverter.to_blocks (md);
            
            expect_true (actual.contains ("<sup id=\"footnote-link-1\" class=\"wp-block-footnote\"><a href=\"#footnote-1\">1</a></sup>"), "Footnote marker in text");
            expect_true (actual.contains ("<!-- wp:footnotes -->"), "Footnotes block start");
            expect_true (actual.contains ("<li id=\"footnote-1\">This is the footnote content. <a href=\"#footnote-link-1\">↩︎</a></li>"), "Footnote list item");
            expect_true (actual.contains ("<!-- /wp:footnotes -->"), "Footnotes block end");
            expect_true (!actual.contains ("[^1]:"), "Footnote definition consumed");
        }

        private static void test_multiline_footnotes () {
            string md = "Text.[^1]\n\n[^1]: Line 1\n    Line 2";
            string actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("Line 1<br/>Line 2"), "Multiline footnote content contains <br/>");
        }

        private static void test_setext_headings () {
            string md = "Heading 1\n=========\n\nHeading 2\n---------";
            string expected = "<!-- wp:heading {\"level\":1} -->\n<h1>Heading 1</h1>\n<!-- /wp:heading -->\n\n" +
                              "<!-- wp:heading {\"level\":2} -->\n<h2>Heading 2</h2>\n<!-- /wp:heading -->\n\n";
            expect_equal (expected, MarkdownConverter.to_blocks (md), "Setext Headings");
        }

        private static void test_strikethrough () {
            string md = "This is ~~deleted~~ text.";
            string actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<s>deleted</s>"), "Strikethrough");
        }

        private static void test_task_lists () {
            string md = "* [ ] Todo\n* [x] Done";
            string actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<input type=\"checkbox\" disabled=\"\" /> Todo"), "Unchecked task");
            expect_true (actual.contains ("<input type=\"checkbox\" checked=\"\" disabled=\"\" /> Done"), "Checked task");
        }

        private static void test_tables () {
            string md = "| Head 1 | Head 2 |\n| --- | --- |\n| Val 1 | Val 2 |";
            string actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<!-- wp:table -->"), "Table block start");
            expect_true (actual.contains ("<thead><tr><th>Head 1</th><th>Head 2</th></tr></thead>"), "Table header");
            expect_true (actual.contains ("<tbody><tr><td>Val 1</td><td>Val 2</td></tr></tbody>"), "Table body");
        }

        private static void test_table_alignment () {
            string md = "| Left | Center | Right |\n| :--- | :---: | ---: |\n| one | two | three |";
            string actual = MarkdownConverter.to_blocks (md);

            expect_true (actual.contains ("<th style=\"text-align:left;\">Left</th>"), "Left Header Alignment");
            expect_true (actual.contains ("<th style=\"text-align:center;\">Center</th>"), "Center Header Alignment");
            expect_true (actual.contains ("<th style=\"text-align:right;\">Right</th>"), "Right Header Alignment");
            expect_true (actual.contains ("<td style=\"text-align:left;\">one</td>"), "Left Cell Alignment");
            expect_true (actual.contains ("<td style=\"text-align:center;\">two</td>"), "Center Cell Alignment");
            expect_true (actual.contains ("<td style=\"text-align:right;\">three</td>"), "Right Cell Alignment");
        }

        private static void test_gallery () {
            string md = "![Img 1](url1)\n![Img 2](url2)";
            string actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<!-- wp:gallery"), "Gallery block start");
            expect_true (actual.contains ("<img src=\"url1\""), "Image 1 in gallery");
            expect_true (actual.contains ("<img src=\"url2\""), "Image 2 in gallery");
            expect_true (!actual.contains ("\n\n<!-- wp:image"), "Images should be grouped, not separate blocks");
        }

        private static void test_escapes () {
            string md = "This is \\*not italic\\* and this is a backslash: \\\\";
            string actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("This is *not italic*"), "Escaped asterisks");
            expect_true (actual.contains ("backslash: " + "\\"), "Escaped backslash");
            expect_true (!actual.contains ("<em>"), "No italics when escaped");

            md = "Code with escape: `\\*`";
            actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<code>\\*</code>"), "Backslash in code span remains");
        }

        private static void test_robustness () {
            // Indented code block
            string md = "Paragraph.\n\n    code block\n    lines";
            string actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<!-- wp:code -->"), "Indented code block detected");
            expect_true (actual.contains ("<code>code block\nlines\n</code>"), "Indented code content");

            // HTML Escaping
            md = "Safe <script>alert(1)</script>";
            actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("&lt;script&gt;"), "HTML tags in text are escaped");

            // Bold/Italic nesting and underscores
            md = "__bold__ and _italic_";
            actual = MarkdownConverter.to_blocks (md);
            expect_true (actual.contains ("<strong>bold</strong>"), "Underscore bold");
            expect_true (actual.contains ("<em>italic</em>"), "Underscore italic");
        }

        private static void test_bug_fix_list_continuation () {
            string md = "* List Item\n\nAfter list.";
            string actual = MarkdownConverter.to_blocks (md);
            expect_true (!actual.contains ("<li>List Item <p>After list.</p> </li>"), "Bug Fix: List Continuation");
            expect_true (actual.contains ("<!-- /wp:list -->\n\n<!-- wp:paragraph -->"), "Bug Fix: List Properly Closed");
        }
    }

    public static int main (string[] args) {
        Test.init (ref args);
        MarkdownTests.register_tests ();
        return Test.run ();
    }
}
