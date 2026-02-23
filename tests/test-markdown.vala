namespace Wordpress {

    public class MarkdownTests : Object {

        public static void run_tests () {
            test_headings ();
            test_paragraphs ();
            test_lists ();
            test_nested_lists ();
            test_code_blocks ();
            test_quotes ();
            test_nested_quotes_and_citations ();
            test_thematic_breaks ();
            test_html_blocks ();
            test_math_blocks ();
            test_inline_formatting ();
            test_image_blocks ();
            test_reference_style ();
            test_footnotes ();
            test_multiline_footnotes ();
            test_setext_headings ();
            test_strikethrough ();
            test_task_lists ();
            test_tables ();
            test_gallery ();
            test_escapes ();
            test_bug_fix_list_continuation ();
        }

        private static void assert_equal (string expected, string actual, string test_name) {
            if (expected == actual) {
                print ("[PASS] %s\n", test_name);
            } else {
                print ("[FAIL] %s\n", test_name);
                print ("Expected: [%s]\n", expected);
                print ("Actual:   [%s]\n", actual);
            }
        }

        private static void assert_true (bool actual, string test_name) {
            if (actual) {
                print ("[PASS] %s\n", test_name);
            } else {
                print ("[FAIL] %s\n", test_name);
            }
        }

        private static void test_headings () {
            string md = "# Heading 1\n## Heading 2\n### Heading 3";
            string expected = "<!-- wp:heading {\"level\":1} -->\n<h1>Heading 1</h1>\n<!-- /wp:heading -->\n\n" +
                              "<!-- wp:heading {\"level\":2} -->\n<h2>Heading 2</h2>\n<!-- /wp:heading -->\n\n" +
                              "<!-- wp:heading {\"level\":3} -->\n<h3>Heading 3</h3>\n<!-- /wp:heading -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "Headings");
        }

        private static void test_paragraphs () {
            string md = "First paragraph.\n\nSecond paragraph.";
            string expected = "<!-- wp:paragraph -->\n<p>First paragraph.</p>\n<!-- /wp:paragraph -->\n\n" +
                              "<!-- wp:paragraph -->\n<p>Second paragraph.</p>\n<!-- /wp:paragraph -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "Paragraphs");
        }

        private static void test_lists () {
            string md = "* Item 1\n* Item 2";
            string expected = "<!-- wp:list {\"ordered\":false} -->\n<ul>\n<li>Item 1</li>\n<li>Item 2</li>\n</ul>\n<!-- /wp:list -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "Unordered List");

            md = "1. First\n2. Second";
            expected = "<!-- wp:list {\"ordered\":true} -->\n<ol>\n<li>First</li>\n<li>Second</li>\n</ol>\n<!-- /wp:list -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "Ordered List");
        }

        private static void test_nested_lists () {
            string md = "* Item 1\n  * Nested 1.1\n* Item 2";
            string expected = "<!-- wp:list {\"ordered\":false} -->\n<ul>\n<li>Item 1\n<ul>\n<li>Nested 1.1</li>\n</ul>\n</li>\n<li>Item 2</li>\n</ul>\n<!-- /wp:list -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "Nested List");
        }

        private static void test_code_blocks () {
            string md = "```vala\nvoid main() {\n    print(\"Hello\");\n}\n```";
            string expected = "<!-- wp:code -->\n<pre class=\"wp-block-code\"><code>void main() {\n    print(&quot;Hello&quot;);\n}\n</code></pre>\n<!-- /wp:code -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "Code Block");
        }

        private static void test_quotes () {
            string md = "> A quote\n> with two lines";
            string expected = "<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\"><!-- wp:paragraph -->\n<p>A quote</p>\n<!-- /wp:paragraph -->\n<!-- wp:paragraph -->\n<p>with two lines</p>\n<!-- /wp:paragraph -->\n</blockquote>\n<!-- /wp:quote -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "Blockquote");
        }

        private static void test_nested_quotes_and_citations () {
            string md = "> Outer\n>> Inner\n> -- Author";
            string expected = "<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\"><!-- wp:paragraph -->\n<p>Outer</p>\n<!-- /wp:paragraph -->\n<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\"><!-- wp:paragraph -->\n<p>Inner</p>\n<!-- /wp:paragraph -->\n</blockquote>\n<!-- /wp:quote -->\n<cite>Author</cite></blockquote>\n<!-- /wp:quote -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "Nested Blockquote and Citation");
        }

        private static void test_thematic_breaks () {
            string md = "---\n***\n* * *";
            string expected = "<!-- wp:separator -->\n<hr class=\"wp-block-separator\"/>\n<!-- /wp:separator -->\n\n" +
                              "<!-- wp:separator -->\n<hr class=\"wp-block-separator\"/>\n<!-- /wp:separator -->\n\n" +
                              "<!-- wp:separator -->\n<hr class=\"wp-block-separator\"/>\n<!-- /wp:separator -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "Thematic Breaks");
        }

        private static void test_html_blocks () {
            string md = "<div>\n<span>Raw HTML</span>\n</div>";
            string expected = "<!-- wp:html -->\n<div>\n<!-- /wp:html -->\n\n" +
                              "<!-- wp:html -->\n<span>Raw HTML</span>\n<!-- /wp:html -->\n\n" +
                              "<!-- wp:html -->\n</div>\n<!-- /wp:html -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "HTML Blocks");
        }

        private static void test_math_blocks () {
            string md = "$$e = mc^2$$";
            string expected = "<!-- wp:latex {\"latex\":\"e = mc^2\"} -->\n<p class=\"wp-block-latex\">$e = mc^2$</p>\n<!-- /wp:latex -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "Math Block (Single Line)");

            md = "$$\na^2 + b^2 = c^2\n$$";
            expected = "<!-- wp:latex {\"latex\":\"a^2 + b^2 = c^2\"} -->\n<p class=\"wp-block-latex\">$a^2 + b^2 = c^2$</p>\n<!-- /wp:latex -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "Math Block (Multi-line)");
        }

        private static void test_inline_formatting () {
            string md = "Text with **bold**, *italic*, [link](https://example.com), and `code`.";
            string actual = MarkdownConverter.to_blocks (md);
            
            assert_true (actual.contains ("<strong>bold</strong>"), "Inline Bold");
            assert_true (actual.contains ("<em>italic</em>"), "Inline Italic");
            assert_true (actual.contains ("<a href=\"https://example.com\">link</a>"), "Inline Link");
            assert_true (actual.contains ("<code>code</code>"), "Inline Code");
        }

        private static void test_image_blocks () {
            string md = "![Alt text](https://example.com/image.png)";
            string expected = "<!-- wp:image -->\n<figure class=\"wp-block-image\"><img src=\"https://example.com/image.png\" alt=\"Alt text\"/></figure>\n<!-- /wp:image -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "Image Block");

            md = "Paragraph with ![Inline Image](https://example.com/inline.png)";
            string actual = MarkdownConverter.to_blocks (md);
            assert_true (actual.contains ("<!-- wp:paragraph -->"), "Inline image remains in paragraph");
            if (!actual.contains ("<img src=\"https://example.com/inline.png\" alt=\"Inline Image\" />")) {
                print ("DEBUG ACTUAL: [%s]\n", actual);
            }
            assert_true (actual.contains ("<img src=\"https://example.com/inline.png\" alt=\"Inline Image\" />"), "Inline image rendered as img tag");
        }

        private static void test_reference_style () {
            string md = "Check [this link][ref] and ![this image][img].\n\n[ref]: https://example.com\n[img]: https://example.com/img.png";
            string actual = MarkdownConverter.to_blocks (md);
            
            assert_true (actual.contains ("<a href=\"https://example.com\">this link</a>"), "Reference Link");
            assert_true (actual.contains ("<img src=\"https://example.com/img.png\" alt=\"this image\" />"), "Reference Image");
            assert_true (!actual.contains ("[ref]:"), "Reference definitions are consumed");

            md = "[collapsed][]\n\n[collapsed]: https://collapsed.com";
            actual = MarkdownConverter.to_blocks (md);
            assert_true (actual.contains ("<a href=\"https://collapsed.com\">collapsed</a>"), "Collapsed Reference Link");
        }

        private static void test_footnotes () {
            string md = "Text with a footnote.[^1]\n\n[^1]: This is the footnote content.";
            string actual = MarkdownConverter.to_blocks (md);
            
            assert_true (actual.contains ("<sup id=\"footnote-link-1\" class=\"wp-block-footnote\"><a href=\"#footnote-1\">1</a></sup>"), "Footnote marker in text");
            assert_true (actual.contains ("<!-- wp:footnotes -->"), "Footnotes block start");
            assert_true (actual.contains ("<li id=\"footnote-1\">This is the footnote content. <a href=\"#footnote-link-1\">↩︎</a></li>"), "Footnote list item");
            assert_true (actual.contains ("<!-- /wp:footnotes -->"), "Footnotes block end");
            assert_true (!actual.contains ("[^1]:"), "Footnote definition consumed");
        }

        private static void test_multiline_footnotes () {
            string md = "Text.[^1]\n\n[^1]: Line 1\n    Line 2";
            string actual = MarkdownConverter.to_blocks (md);
            assert_true (actual.contains ("Line 1<br/>Line 2"), "Multiline footnote content contains <br/>");
        }

        private static void test_setext_headings () {
            string md = "Heading 1\n=========\n\nHeading 2\n---------";
            string expected = "<!-- wp:heading {\"level\":1} -->\n<h1>Heading 1</h1>\n<!-- /wp:heading -->\n\n" +
                              "<!-- wp:heading {\"level\":2} -->\n<h2>Heading 2</h2>\n<!-- /wp:heading -->\n\n";
            assert_equal (expected, MarkdownConverter.to_blocks (md), "Setext Headings");
        }

        private static void test_strikethrough () {
            string md = "This is ~~deleted~~ text.";
            string actual = MarkdownConverter.to_blocks (md);
            assert_true (actual.contains ("<s>deleted</s>"), "Strikethrough");
        }

        private static void test_task_lists () {
            string md = "* [ ] Todo\n* [x] Done";
            string actual = MarkdownConverter.to_blocks (md);
            assert_true (actual.contains ("<input type=\"checkbox\" disabled=\"\" /> Todo"), "Unchecked task");
            assert_true (actual.contains ("<input type=\"checkbox\" checked=\"\" disabled=\"\" /> Done"), "Checked task");
        }

        private static void test_tables () {
            string md = "| Head 1 | Head 2 |\n| --- | --- |\n| Val 1 | Val 2 |";
            string actual = MarkdownConverter.to_blocks (md);
            assert_true (actual.contains ("<!-- wp:table -->"), "Table block start");
            assert_true (actual.contains ("<thead><tr><th>Head 1</th><th>Head 2</th></tr></thead>"), "Table header");
            assert_true (actual.contains ("<tbody><tr><td>Val 1</td><td>Val 2</td></tr></tbody>"), "Table body");
        }

        private static void test_gallery () {
            string md = "![Img 1](url1)\n![Img 2](url2)";
            string actual = MarkdownConverter.to_blocks (md);
            assert_true (actual.contains ("<!-- wp:gallery"), "Gallery block start");
            assert_true (actual.contains ("<img src=\"url1\""), "Image 1 in gallery");
            assert_true (actual.contains ("<img src=\"url2\""), "Image 2 in gallery");
            assert_true (!actual.contains ("\n\n<!-- wp:image"), "Images should be grouped, not separate blocks");
        }

        private static void test_escapes () {
            string md = "This is \\*not italic\\* and this is a backslash: \\\\";
            string actual = MarkdownConverter.to_blocks (md);
            assert_true (actual.contains ("This is *not italic*"), "Escaped asterisks");
            assert_true (actual.contains ("backslash: \\"), "Escaped backslash");
            assert_true (!actual.contains ("<em>"), "No italics when escaped");

            md = "Code with escape: `\\*`";
            actual = MarkdownConverter.to_blocks (md);
            assert_true (actual.contains ("<code>\\*</code>"), "Backslash in code span remains");
        }

        private static void test_bug_fix_list_continuation () {
            string md = "* List Item\n\nAfter list.";
            string actual = MarkdownConverter.to_blocks (md);
            assert_true (!actual.contains ("<li>List Item <p>After list.</p> </li>"), "Bug Fix: List Continuation");
            assert_true (actual.contains ("<!-- /wp:list -->\n\n<!-- wp:paragraph -->"), "Bug Fix: List Properly Closed");
        }
    }

    public static int main (string[] args) {
        MarkdownTests.run_tests ();
        return 0;
    }
}
