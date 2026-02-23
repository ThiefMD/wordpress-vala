namespace Wordpress {

    private enum BlockType {
        DOCUMENT,
        HEADING,
        PARAGRAPH,
        LIST,
        LIST_ITEM,
        CODE_BLOCK,
        QUOTE,
        THEMATIC_BREAK,
        HTML,
        MATH,
        IMAGE
    }

    private class Block : Object {
        public BlockType block_type { get; set; }
        public int level { get; set; } // For headings
        public bool ordered { get; set; } // For lists
        public string content { get; set; }
        public string alt { get; set; } // For images
        public Gee.ArrayList<Block> children { get; set; }
        public Block parent { get; set; }
        public bool open { get; set; }
        public int indent { get; set; }

        public Block (BlockType type, int indent = 0) {
            this.block_type = type;
            this.content = "";
            this.alt = "";
            this.children = new Gee.ArrayList<Block> ();
            this.open = true;
            this.indent = indent;
        }

        public void add_child (Block child) {
            child.parent = this;
            this.children.add (child);
        }
    }

    public class MarkdownConverter : Object {

        public static string to_blocks (string markdown) {
            var parser = new Parser ();
            var root = parser.parse (markdown);
            return render (root);
        }

        private static string render (Block block) {
            var builder = new StringBuilder ();
            
            foreach (var child in block.children) {
                switch (child.block_type) {
                    case BlockType.HEADING:
                        builder.append ("<!-- wp:heading {\"level\":%d} -->\n<h%d>%s</h%d>\n<!-- /wp:heading -->\n\n".printf (child.level, child.level, parse_inline (child.content.strip ()), child.level));
                        break;
                    case BlockType.PARAGRAPH:
                        builder.append ("<!-- wp:paragraph -->\n<p>%s</p>\n<!-- /wp:paragraph -->\n\n".printf (parse_inline (child.content.strip ())));
                        break;
                    case BlockType.LIST:
                        builder.append ("<!-- wp:list {\"ordered\":%s} -->\n<%s>\n".printf (child.ordered ? "true" : "false", child.ordered ? "ol" : "ul"));
                        builder.append (render_list_items (child));
                        builder.append ("</%s>\n<!-- /wp:list -->\n\n".printf (child.ordered ? "ol" : "ul"));
                        break;
                    case BlockType.CODE_BLOCK:
                        builder.append ("<!-- wp:code -->\n<pre class=\"wp-block-code\"><code>");
                        builder.append (Markup.escape_text (child.content)); 
                        builder.append ("</code></pre>\n<!-- /wp:code -->\n\n");
                        break;
                    case BlockType.QUOTE:
                        builder.append ("<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\">");
                        builder.append (render_inner_blocks (child));
                        if (child.content != "") {
                            builder.append ("<cite>%s</cite>".printf (parse_inline (child.content.strip ())));
                        }
                        builder.append ("</blockquote>\n<!-- /wp:quote -->\n\n");
                        break;
                    case BlockType.THEMATIC_BREAK:
                        builder.append ("<!-- wp:separator -->\n<hr class=\"wp-block-separator\"/>\n<!-- /wp:separator -->\n\n");
                        break;
                    case BlockType.HTML:
                        builder.append ("<!-- wp:html -->\n%s\n<!-- /wp:html -->\n\n".printf (child.content));
                        break;
                    case BlockType.MATH:
                        string escaped_math = Markup.escape_text (child.content.strip ());
                        builder.append ("<!-- wp:latex {\"latex\":\"%s\"} -->\n<p class=\"wp-block-latex\">$%s$</p>\n<!-- /wp:latex -->\n\n".printf (escaped_math, escaped_math));
                        break;
                    case BlockType.IMAGE:
                        builder.append ("<!-- wp:image -->\n<figure class=\"wp-block-image\"><img src=\"%s\" alt=\"%s\"/></figure>\n<!-- /wp:image -->\n\n".printf (child.content, child.alt));
                        break;
                    default:
                        break;
                }
            }
            return builder.str;
        }
        
        private static string render_inner_blocks (Block block) {
             var builder = new StringBuilder ();
             foreach (var child in block.children) {
                 switch (child.block_type) {
                    case BlockType.PARAGRAPH:
                        builder.append ("<!-- wp:paragraph -->\n<p>%s</p>\n<!-- /wp:paragraph -->\n".printf (parse_inline (child.content.strip ())));
                        break;
                    case BlockType.IMAGE:
                        builder.append ("<!-- wp:image -->\n<figure class=\"wp-block-image\"><img src=\"%s\" alt=\"%s\"/></figure>\n<!-- /wp:image -->\n".printf (child.content, child.alt));
                        break;
                    case BlockType.LIST:
                        builder.append ("<!-- wp:list {\"ordered\":%s} -->\n<%s>\n".printf (child.ordered ? "true" : "false", child.ordered ? "ol" : "ul"));
                        builder.append (render_list_items (child));
                        builder.append ("</%s>\n<!-- /wp:list -->\n".printf (child.ordered ? "ol" : "ul"));
                        break;
                    case BlockType.QUOTE:
                        builder.append ("<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\">");
                        builder.append (render_inner_blocks (child));
                        if (child.content != "") {
                            builder.append ("<cite>%s</cite>".printf (parse_inline (child.content.strip ())));
                        }
                        builder.append ("</blockquote>\n<!-- /wp:quote -->\n");
                        break;
                    default:
                        break;
                 }
             }
             return builder.str;
        }

        private static string render_list_items (Block list_block) {
            var builder = new StringBuilder ();
            foreach (var item in list_block.children) {
                 if (item.block_type == BlockType.LIST_ITEM) {
                     builder.append ("<li>%s".printf (parse_inline (item.content.strip ())));
                     foreach (var child in item.children) {
                         switch (child.block_type) {
                            case BlockType.LIST:
                                builder.append ("\n<%s>\n".printf (child.ordered ? "ol" : "ul"));
                                builder.append (render_list_items (child));
                                builder.append ("</%s>\n".printf (child.ordered ? "ol" : "ul"));
                                break;
                            case BlockType.PARAGRAPH:
                                builder.append ("\n<p>%s</p>\n".printf (parse_inline (child.content.strip ())));
                                break;
                            case BlockType.IMAGE:
                                builder.append ("\n<!-- wp:image -->\n<figure class=\"wp-block-image\"><img src=\"%s\" alt=\"%s\"/></figure>\n<!-- /wp:image -->\n".printf (child.content, child.alt));
                                break;
                            case BlockType.CODE_BLOCK:
                                builder.append ("\n<pre class=\"wp-block-code\"><code>");
                                builder.append (Markup.escape_text (child.content)); 
                                builder.append ("</code></pre>\n");
                                break;
                            case BlockType.HEADING:
                                builder.append ("\n<h%d>%s</h%d>\n".printf (child.level, parse_inline (child.content.strip ()), child.level));
                                break;
                            case BlockType.QUOTE:
                                builder.append ("\n<blockquote class=\"wp-block-quote\">");
                                builder.append (render_inner_blocks (child));
                                builder.append ("</blockquote>\n");
                                break;
                            case BlockType.THEMATIC_BREAK:
                                builder.append ("\n<hr class=\"wp-block-separator\"/>\n");
                                break;
                            case BlockType.HTML:
                                builder.append ("\n%s\n".printf (child.content));
                                break;
                            default:
                                break;
                         }
                     }
                     builder.append ("</li>\n");
                 }
            }
            return builder.str;
        }

        private static string parse_inline (string text) {
             string result = text;
            try {
                var bold_regex = new Regex ("\\*\\*(.*?)\\*\\*");
                result = bold_regex.replace (result, -1, 0, "<strong>\\1</strong>");
                
                var italic_regex = new Regex ("\\*(.*?)\\*");
                result = italic_regex.replace (result, -1, 0, "<em>\\1</em>");

                var img_regex = new Regex ("!\\[(.*?)\\]\\((.*?)\\)");
                result = img_regex.replace (result, -1, 0, "<img src=\"\\2\" alt=\"\\1\" />");

                var link_regex = new Regex ("\\[(.*?)\\]\\((.*?)\\)");
                result = link_regex.replace (result, -1, 0, "<a href=\"\\2\">\\1</a>");
                
                var code_regex = new Regex ("`(.*?)`");
                result = code_regex.replace (result, -1, 0, "<code>\\1</code>");

            } catch (Error e) {
                warning ("Inline parsing error: %s", e.message);
            }
            return result;
        }
    }

    private class Parser : Object {
        private Block root;
        private Block current;

        public Block parse (string markdown) {
            root = new Block (BlockType.DOCUMENT);
            current = root;
            
            var lines = markdown.split ("\n");
            foreach (var line in lines) {
                process_line (line);
            }
            return root;
        }

        private int get_indent (string line) {
            int i = 0;
            while (i < line.length && line[i] == ' ') {
                i++;
            }
            return i;
        }

        private void process_line (string line) {
            int indent = get_indent (line);
            string trimmed = line.strip ();

            if (current.block_type == BlockType.CODE_BLOCK && current.open) {
                if (trimmed.has_prefix ("```")) {
                    current.open = false;
                    current = current.parent;
                } else {
                    current.content += line + "\n";
                }
                return;
            }

            if (current.block_type == BlockType.MATH && current.open) {
                if (trimmed.has_suffix ("$$")) {
                    current.content += line.replace ("$$", "").strip ();
                    current.open = false;
                    current = current.parent;
                } else {
                    current.content += line + "\n";
                }
                return;
            }

            if (trimmed == "") {
                if (current.block_type == BlockType.PARAGRAPH) {
                    current.open = false;
                    current = current.parent;
                } else if (current.block_type == BlockType.LIST_ITEM) {
                    // We don't necessarily close the list item immediately,
                    // but we might want to mark it as ready to close if the next line is not indented.
                    // For now, let's keep it open to allow for multi-paragraph list items.
                }
                return;
            }

            // Move up if indentation decreased
            while (current != root && indent < current.indent) {
                current.open = false;
                current = current.parent;
            }

            // Special case for list items: if indentation is 0 and it's not a list marker, close the list
            if (current != root && indent == 0 && (current.block_type == BlockType.LIST || current.block_type == BlockType.LIST_ITEM)) {
                bool is_new_list_marker = trimmed.has_prefix ("* ") || trimmed.has_prefix ("- ") || trimmed.has_prefix ("+ ") || Regex.match_simple ("^(\\d+)\\. (.*)", trimmed);
                if (!is_new_list_marker) {
                    while (current != root && (current.block_type == BlockType.LIST || current.block_type == BlockType.LIST_ITEM)) {
                        current.open = false;
                        current = current.parent;
                    }
                }
            }

            // Code block
            if (trimmed.has_prefix ("```")) {
                close_paragraph ();
                var code_block = new Block (BlockType.CODE_BLOCK, indent);
                add_block (code_block);
                current = code_block;
                return;
            }

            // HTML Block
            if (trimmed.has_prefix ("<")) {
                close_paragraph ();
                var html_block = new Block (BlockType.HTML, indent);
                html_block.content = trimmed;
                add_block (html_block);
                return;
            }

            // Math Block
            if (trimmed.has_prefix ("$$")) {
                close_paragraph ();
                var math_block = new Block (BlockType.MATH, indent);
                if (trimmed.length > 2 && trimmed.has_suffix ("$$")) {
                    math_block.content = trimmed.substring (2, trimmed.length - 4).strip ();
                    math_block.open = false;
                    add_block (math_block);
                } else {
                    add_block (math_block);
                    current = math_block;
                }
                return;
            }

            // Headings
            if (trimmed.has_prefix ("#")) {
                close_paragraph ();
                int level = 0;
                while (level < trimmed.length && trimmed[level] == '#') {
                    level++;
                }
                // Headings should be at root or in a quote, but usually not nested in lists by simple indentation
                // unless explicitly intended. For now, let's move out of lists.
                while (current != root && (current.block_type == BlockType.LIST || current.block_type == BlockType.LIST_ITEM)) {
                    current.open = false;
                    current = current.parent;
                }
                var heading = new Block (BlockType.HEADING, indent);
                heading.level = level;
                heading.content = trimmed.substring (level).strip ();
                add_block (heading);
                return;
            }

            // Blockquotes
            if (trimmed.has_prefix (">")) {
                close_paragraph ();
                
                int quote_level = 0;
                string quote_trimmed = trimmed;
                while (quote_trimmed.has_prefix (">")) {
                    quote_level++;
                    quote_trimmed = quote_trimmed.substring (1).strip ();
                }

                // Navigate to the correct quote level
                int current_quote_level = 0;
                Block? temp = current;
                while (temp != null && temp != root) {
                    if (temp.block_type == BlockType.QUOTE) {
                        current_quote_level++;
                    }
                    temp = temp.parent;
                }

                // If we need more levels, create them
                while (current_quote_level < quote_level) {
                    var new_quote = new Block (BlockType.QUOTE, indent);
                    add_block (new_quote);
                    current = new_quote;
                    current_quote_level++;
                }

                // If we are deeper than needed, move up
                while (current_quote_level > quote_level && current != root) {
                    current.open = false;
                    current = current.parent;
                    if (current.block_type == BlockType.QUOTE) {
                        current_quote_level--;
                    }
                }
                
                // Ensure current is a QUOTE block at the right level
                while (current != root && current.block_type != BlockType.QUOTE) {
                    current.open = false;
                    current = current.parent;
                }

                if (quote_trimmed != "") {
                    // Check for citation: starts with "-- " or "— "
                    if (quote_trimmed.has_prefix ("-- ") || quote_trimmed.has_prefix ("— ")) {
                        current.content = quote_trimmed.substring (quote_trimmed.has_prefix ("-- ") ? 3 : 2).strip ();
                    } else {
                        var para = new Block (BlockType.PARAGRAPH, indent + 1);
                        para.content = quote_trimmed;
                        current.add_child (para);
                        current = para;
                    }
                }
                return;
            }

            // Lists
            bool is_unordered = trimmed.has_prefix ("* ") || trimmed.has_prefix ("- ") || trimmed.has_prefix ("+ ");
            bool is_ordered = Regex.match_simple ("^(\\d+)\\. (.*)", trimmed);

            if (is_unordered || is_ordered) {
                close_paragraph ();
                
                // If we are in a list item and indent is same, we want to move to parent list
                if (current.block_type == BlockType.LIST_ITEM && indent <= current.indent) {
                     current = current.parent;
                }

                // If indent is more than current list, it's a nested list
                if (current.block_type == BlockType.LIST_ITEM && indent > current.indent) {
                     var list = new Block (BlockType.LIST, indent);
                     list.ordered = is_ordered;
                     current.add_child (list);
                     current = list;
                } else if (current.block_type != BlockType.LIST || indent > current.indent) {
                    var list = new Block (BlockType.LIST, indent);
                    list.ordered = is_ordered;
                    add_block (list);
                    current = list;
                } else if (current.block_type == BlockType.LIST && current.ordered != is_ordered && indent == current.indent) {
                    // Switch list type at same level
                    current.open = false;
                    current = current.parent;
                    var list = new Block (BlockType.LIST, indent);
                    list.ordered = is_ordered;
                    add_block (list);
                    current = list;
                }

                var item = new Block (BlockType.LIST_ITEM, indent);
                if (is_unordered) {
                    item.content = trimmed.substring (2).strip ();
                } else {
                    try {
                        var regex = new Regex ("^(\\d+)\\. (.*)");
                        MatchInfo match_info;
                        if (regex.match (trimmed, 0, out match_info)) {
                            item.content = match_info.fetch (2);
                        }
                    } catch (Error e) {}
                }
                current.add_child (item);
                current = item;
                return;
            }

            // Thematic break
            if (Regex.match_simple ("^(\\*{3,}|-{3,}|_{3,})$", trimmed)) {
                 close_paragraph ();
                 add_block (new Block (BlockType.THEMATIC_BREAK, indent));
                 return;
            }

            // Image block
            try {
                var img_regex = new Regex ("^!\\[(.*?)\\]\\((.*?)\\)$");
                MatchInfo match_info;
                if (img_regex.match (trimmed, 0, out match_info)) {
                    close_paragraph ();
                    var image_block = new Block (BlockType.IMAGE, indent);
                    image_block.alt = match_info.fetch (1);
                    image_block.content = match_info.fetch (2); // URL
                    add_block (image_block);
                    return;
                }
            } catch (Error e) {}

            // Paragraph or continuation
            if (current.block_type == BlockType.PARAGRAPH && current.open) {
                current.content += " " + trimmed;
            } else if (current.block_type == BlockType.LIST_ITEM) {
                // New paragraph inside list item
                var para = new Block (BlockType.PARAGRAPH, indent);
                para.content = trimmed;
                current.add_child (para);
                current = para;
            } else {
                var para = new Block (BlockType.PARAGRAPH, indent);
                para.content = trimmed;
                add_block (para);
                current = para;
            }
        }

        private void close_paragraph () {
            if (current.block_type == BlockType.PARAGRAPH) {
                current.open = false;
                current = current.parent;
            }
        }

        private void add_block (Block block) {
            if (current.block_type == BlockType.DOCUMENT || current.block_type == BlockType.QUOTE || current.block_type == BlockType.LIST_ITEM) {
                current.add_child (block);
            } else if (current.parent != null) {
                current = current.parent;
                add_block (block);
            }
        }
    }
}
