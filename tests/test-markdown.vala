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
            string md = "---\n***";
            string expected = "<!-- wp:separator -->\n<hr class=\"wp-block-separator\"/>\n<!-- /wp:separator -->\n\n" +
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
