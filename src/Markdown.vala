namespace Wordpress {

    private enum BlockType {
        DOCUMENT, HEADING, PARAGRAPH, LIST, LIST_ITEM, CODE_BLOCK, QUOTE, THEMATIC_BREAK, HTML, MATH, IMAGE, TABLE, GALLERY
    }

    private class Block : Object {
        public BlockType block_type { get; set; }
        public int level { get; set; }
        public bool ordered { get; set; }
        public string content { get; set; }
        public string alt { get; set; }
        public Gee.ArrayList<Block> children { get; set; }
        public Block? parent { get; set; }
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

        public void close () {
            this.open = false;
            foreach (var child in children) {
                if (child.open) child.close ();
            }
        }
    }

    private class FootnoteContext : Object {
        public Gee.Map<string, string> definitions;
        public Gee.List<string> used_ids;
        
        public FootnoteContext (Gee.Map<string, string> definitions) {
            this.definitions = definitions;
            this.used_ids = new Gee.ArrayList<string> ();
        }

        public int get_or_add (string id) {
            int index = used_ids.index_of (id);
            if (index == -1) {
                if (definitions.has_key (id)) {
                    used_ids.add (id);
                    return used_ids.size;
                }
                return -1;
            }
            return index + 1;
        }
    }

    public class MarkdownConverter : Object {

        public static string to_blocks (string markdown) {
            var parser = new Parser ();
            var root = parser.parse (markdown);
            var footnote_ctx = new FootnoteContext (parser.footnotes);
            
            string content = render (root, parser.references, footnote_ctx);
            
            if (footnote_ctx.used_ids.size > 0) {
                var builder = new StringBuilder (content);
                builder.append ("<!-- wp:footnotes -->\n<ol class=\"wp-block-footnotes\">\n");
                for (int i = 0; i < footnote_ctx.used_ids.size; i++) {
                    string id = footnote_ctx.used_ids.get (i);
                    string raw_content = parser.footnotes.get (id);
                    string footnote_content = parse_inline (raw_content, parser.references, footnote_ctx).replace ("\n", "<br/>");
                    builder.append ("<li id=\"footnote-%d\">%s <a href=\"#footnote-link-%d\">↩︎</a></li>\n".printf (i + 1, footnote_content, i + 1));
                }
                builder.append ("</ol>\n<!-- /wp:footnotes -->\n\n");
                return builder.str;
            }

            return content;
        }

        private static string escape (string text) {
            return Markup.escape_text (text);
        }

        private static string render (Block block, Gee.Map<string, string> references, FootnoteContext footnote_ctx) {
            var builder = new StringBuilder ();
            
            foreach (var child in block.children) {
                switch (child.block_type) {
                    case BlockType.HEADING:
                        builder.append ("<!-- wp:heading {\"level\":%d} -->\n<h%d>%s</h%d>\n<!-- /wp:heading -->\n\n".printf (child.level, child.level, parse_inline (child.content.strip (), references, footnote_ctx), child.level));
                        break;
                    case BlockType.PARAGRAPH:
                        builder.append ("<!-- wp:paragraph -->\n<p>%s</p>\n<!-- /wp:paragraph -->\n\n".printf (parse_inline (child.content.strip (), references, footnote_ctx)));
                        break;
                    case BlockType.LIST:
                        builder.append ("<!-- wp:list {\"ordered\":%s} -->\n<%s>\n".printf (child.ordered ? "true" : "false", child.ordered ? "ol" : "ul"));
                        builder.append (render_list_items (child, references, footnote_ctx));
                        builder.append ("</%s>\n<!-- /wp:list -->\n\n".printf (child.ordered ? "ol" : "ul"));
                        break;
                    case BlockType.CODE_BLOCK:
                        builder.append ("<!-- wp:code -->\n<pre class=\"wp-block-code\"><code>");
                        builder.append (escape (child.content)); 
                        builder.append ("</code></pre>\n<!-- /wp:code -->\n\n");
                        break;
                    case BlockType.QUOTE:
                        builder.append ("<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\">");
                        builder.append (render_inner_blocks (child, references, footnote_ctx));
                        if (child.content != "") {
                            builder.append ("<cite>%s</cite>".printf (parse_inline (child.content.strip (), references, footnote_ctx)));
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
                        string escaped_math = escape (child.content.strip ());
                        builder.append ("<!-- wp:latex {\"latex\":\"%s\"} -->\n<p class=\"wp-block-latex\">$%s$</p>\n<!-- /wp:latex -->\n\n".printf (escaped_math, escaped_math));
                        break;
                    case BlockType.IMAGE:
                        builder.append ("<!-- wp:image -->\n<figure class=\"wp-block-image\"><img src=\"%s\" alt=\"%s\"/></figure>\n<!-- /wp:image -->\n\n".printf (child.content, escape (child.alt)));
                        break;
                    case BlockType.TABLE:
                        builder.append ("<!-- wp:table -->\n<figure class=\"wp-block-table\"><table>");
                        render_table (child.content, builder, references, footnote_ctx);
                        builder.append ("</table></figure>\n<!-- /wp:table -->\n\n");
                        break;
                    case BlockType.GALLERY:
                        builder.append ("<!-- wp:gallery {\"linkTo\":\"none\"} -->\n<figure class=\"wp-block-gallery has-nested-images columns-default is-cropped\">");
                        foreach (var img in child.children) {
                            builder.append ("<!-- wp:image -->\n<figure class=\"wp-block-image\"><img src=\"%s\" alt=\"%s\"/></figure>\n<!-- /wp:image -->\n".printf (img.content, escape (img.alt)));
                        }
                        builder.append ("</figure>\n<!-- /wp:gallery -->\n\n");
                        break;
                    default:
                        break;
                }
            }
            return builder.str;
        }

        private static void render_table (string table_content, StringBuilder builder, Gee.Map<string, string> references, FootnoteContext footnote_ctx) {
            var lines = table_content.strip ().split ("\n");
            if (lines.length < 2) return;

            builder.append ("<thead><tr>");
            var header_cells = lines[0].split ("|");
            foreach (var cell in header_cells) {
                string trimmed = cell.strip ();
                if (trimmed == "" && (cell == header_cells[0] || cell == header_cells[header_cells.length-1])) continue;
                builder.append ("<th>%s</th>".printf (parse_inline (trimmed, references, footnote_ctx)));
            }
            builder.append ("</tr></thead>");

            if (lines.length > 2) {
                builder.append ("<tbody>");
                for (int i = 2; i < lines.length; i++) {
                    builder.append ("<tr>");
                    var cells = lines[i].split ("|");
                    foreach (var cell in cells) {
                        string trimmed = cell.strip ();
                        if (trimmed == "" && (cell == cells[0] || cell == cells[cells.length-1])) continue;
                        builder.append ("<td>%s</td>".printf (parse_inline (trimmed, references, footnote_ctx)));
                    }
                    builder.append ("</tr>");
                }
                builder.append ("</tbody>");
            }
        }
        
        private static string render_inner_blocks (Block block, Gee.Map<string, string> references, FootnoteContext footnote_ctx) {
             var builder = new StringBuilder ();
             foreach (var child in block.children) {
                 switch (child.block_type) {
                    case BlockType.PARAGRAPH:
                        builder.append ("<!-- wp:paragraph -->\n<p>%s</p>\n<!-- /wp:paragraph -->\n".printf (parse_inline (child.content.strip (), references, footnote_ctx)));
                        break;
                    case BlockType.IMAGE:
                        builder.append ("<!-- wp:image -->\n<figure class=\"wp-block-image\"><img src=\"%s\" alt=\"%s\"/></figure>\n<!-- /wp:image -->\n".printf (child.content, escape (child.alt)));
                        break;
                    case BlockType.GALLERY:
                        builder.append ("<!-- wp:gallery {\"linkTo\":\"none\"} -->\n<figure class=\"wp-block-gallery has-nested-images columns-default is-cropped\">");
                        foreach (var img in child.children) {
                            builder.append ("<!-- wp:image -->\n<figure class=\"wp-block-image\"><img src=\"%s\" alt=\"%s\"/></figure>\n<!-- /wp:image -->\n".printf (img.content, escape (img.alt)));
                        }
                        builder.append ("</figure>\n<!-- /wp:gallery -->\n");
                        break;
                    case BlockType.LIST:
                        builder.append ("<!-- wp:list {\"ordered\":%s} -->\n<%s>\n".printf (child.ordered ? "true" : "false", child.ordered ? "ol" : "ul"));
                        builder.append (render_list_items (child, references, footnote_ctx));
                        builder.append ("</%s>\n<!-- /wp:list -->\n".printf (child.ordered ? "ol" : "ul"));
                        break;
                    case BlockType.QUOTE:
                        builder.append ("<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\">");
                        builder.append (render_inner_blocks (child, references, footnote_ctx));
                        if (child.content != "") {
                            builder.append ("<cite>%s</cite>".printf (parse_inline (child.content.strip (), references, footnote_ctx)));
                        }
                        builder.append ("</blockquote>\n<!-- /wp:quote -->\n");
                        break;
                    default:
                        break;
                 }
             }
             return builder.str;
        }

        private static string render_list_items (Block list_block, Gee.Map<string, string> references, FootnoteContext footnote_ctx) {
            var builder = new StringBuilder ();
            foreach (var item in list_block.children) {
                 if (item.block_type == BlockType.LIST_ITEM) {
                     string content = item.content.strip ();
                     string task_prefix = "";
                     if (content.has_prefix ("[ ] ")) {
                         task_prefix = "<input type=\"checkbox\" disabled=\"\" /> ";
                         content = content.substring (4);
                     } else if (content.has_prefix ("[x] ")) {
                         task_prefix = "<input type=\"checkbox\" checked=\"\" disabled=\"\" /> ";
                         content = content.substring (4);
                     }

                     builder.append ("<li>%s%s".printf (task_prefix, parse_inline (content, references, footnote_ctx)));
                     foreach (var child in item.children) {
                         switch (child.block_type) {
                            case BlockType.LIST:
                                builder.append ("\n<%s>\n".printf (child.ordered ? "ol" : "ul"));
                                builder.append (render_list_items (child, references, footnote_ctx));
                                builder.append ("</%s>\n".printf (child.ordered ? "ol" : "ul"));
                                break;
                            case BlockType.PARAGRAPH:
                                builder.append ("\n<p>%s</p>\n".printf (parse_inline (child.content.strip (), references, footnote_ctx)));
                                break;
                            case BlockType.IMAGE:
                                builder.append ("\n<!-- wp:image -->\n<figure class=\"wp-block-image\"><img src=\"%s\" alt=\"%s\"/></figure>\n<!-- /wp:image -->\n".printf (child.content, escape (child.alt)));
                                break;
                            case BlockType.GALLERY:
                                builder.append ("\n<!-- wp:gallery {\"linkTo\":\"none\"} -->\n<figure class=\"wp-block-gallery has-nested-images columns-default is-cropped\">");
                                foreach (var img in child.children) {
                                    builder.append ("<!-- wp:image -->\n<figure class=\"wp-block-image\"><img src=\"%s\" alt=\"%s\"/></figure>\n<!-- /wp:image -->\n".printf (img.content, escape (img.alt)));
                                }
                                builder.append ("</figure>\n<!-- /wp:gallery -->\n");
                                break;
                            case BlockType.CODE_BLOCK:
                                builder.append ("\n<pre class=\"wp-block-code\"><code>");
                                builder.append (escape (child.content)); 
                                builder.append ("</code></pre>\n");
                                break;
                            case BlockType.HEADING:
                                builder.append ("\n<h%d>%s</h%d>\n".printf (child.level, parse_inline (child.content.strip (), references, footnote_ctx), child.level));
                                break;
                            case BlockType.QUOTE:
                                builder.append ("\n<blockquote class=\"wp-block-quote\">");
                                builder.append (render_inner_blocks (child, references, footnote_ctx));
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

        private static string parse_inline (string text, Gee.Map<string, string> references, FootnoteContext footnote_ctx) {
             var code_spans = new Gee.ArrayList<string> ();
             var escaped_chars = new Gee.ArrayList<string> ();
             string result = text;
            try {
                // 1. Extract code spans (raw)
                var code_span_regex = new Regex ("`(.*?)`|``(.*?)``");
                result = code_span_regex.replace_eval (result, -1, 0, 0, (match_info, res) => {
                    string content = match_info.fetch (1);
                    if (content == null) content = match_info.fetch (2);
                    code_spans.add (content);
                    res.append ("ZZCODE%dZZ".printf (code_spans.size - 1));
                    return false;
                });

                // 2. Extract escaped chars (raw)
                var escape_token_regex = new Regex ("\\\\([\\\\\\*\\_\\~\\!\\[\\]\\(\\)\\#\\|\\`\\.])");
                result = escape_token_regex.replace_eval (result, -1, 0, 0, (match_info, res) => {
                    escaped_chars.add (match_info.fetch (1));
                    res.append ("ZZESC%dZZ".printf (escaped_chars.size - 1));
                    return false;
                });

                // 3. Escape everything else (now that tokens are protected)
                result = escape (result);

                // 4. Formatting
                var bold_regex = new Regex ("\\*\\*(.*?)\\*\\*|\\__(.*?)__");
                result = bold_regex.replace (result, -1, 0, "<strong>\\1\\2</strong>");
                
                var italic_regex = new Regex ("\\*(.*?)\\*|\\_(.*?)_");
                result = italic_regex.replace (result, -1, 0, "<em>\\1\\2</em>");

                var strike_regex = new Regex ("~~(.*?)~~");
                result = strike_regex.replace (result, -1, 0, "<s>\\1</s>");

                var img_regex = new Regex ("!\\[(.*?)\\]\\((.*?)\\)");
                result = img_regex.replace (result, -1, 0, "<img src=\"\\2\" alt=\"\\1\" />");

                var ref_img_regex = new Regex ("!\\[(.*?)\\]\\[(.*?)\\]");
                result = ref_img_regex.replace_eval (result, -1, 0, 0, (match_info, res) => {
                    string alt = match_info.fetch (1);
                    string id = match_info.fetch (2);
                    if (id == "") id = alt;
                    
                    string? url = references.get (id.down ());
                    if (url != null) {
                        res.append ("<img src=\"%s\" alt=\"%s\" />".printf (url, alt));
                    } else {
                        res.append (match_info.fetch (0));
                    }
                    return false;
                });

                var link_regex = new Regex ("\\[(.*?)\\]\\((.*?)\\)");
                result = link_regex.replace (result, -1, 0, "<a href=\"\\2\">\\1</a>");

                var ref_link_regex = new Regex ("\\[(.*?)\\]\\[(.*?)\\]");
                result = ref_link_regex.replace_eval (result, -1, 0, 0, (match_info, res) => {
                    string text_content = match_info.fetch (1);
                    string id = match_info.fetch (2);
                    if (id == "") id = text_content;

                    string? url = references.get (id.down ());
                    if (url != null) {
                        res.append ("<a href=\"%s\">%s</a>".printf (url, text_content));
                    } else {
                        res.append (match_info.fetch (0));
                    }
                    return false;
                });
                
                var footnote_regex = new Regex ("\\[\\^(.*?)\\]");
                result = footnote_regex.replace_eval (result, -1, 0, 0, (match_info, res) => {
                    string id = match_info.fetch (1);
                    int num = footnote_ctx.get_or_add (id);
                    if (num != -1) {
                        res.append ("<sup id=\"footnote-link-%d\" class=\"wp-block-footnote\"><a href=\"#footnote-%d\">%d</a></sup>".printf (num, num, num));
                    } else {
                        res.append (match_info.fetch (0));
                    }
                    return false;
                });

                // 5. Restore tokens (and escape them as they are restored)
                var restore_escape_regex = new Regex ("ZZESC(\\d+)ZZ");
                result = restore_escape_regex.replace_eval (result, -1, 0, 0, (match_info, res) => {
                    int index = int.parse (match_info.fetch (1));
                    res.append (escape (escaped_chars.get (index)));
                    return false;
                });

                var restore_code_regex = new Regex ("ZZCODE(\\d+)ZZ");
                result = restore_code_regex.replace_eval (result, -1, 0, 0, (match_info, res) => {
                    int index = int.parse (match_info.fetch (1));
                    res.append ("<code>%s</code>".printf (escape (code_spans.get (index))));
                    return false;
                });

            } catch (Error e) {
                warning ("Inline parsing error: %s", e.message);
            }
            return result;
        }
    }

    private class Parser : Object {
        private Block root;
        private Block current;
        public Gee.HashMap<string, string> references { get; private set; }
        public Gee.HashMap<string, string> footnotes { get; private set; }
        private string? last_footnote_id = null;

        public Parser () {
            references = new Gee.HashMap<string, string> ();
            footnotes = new Gee.HashMap<string, string> ();
        }

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

        private void close_paragraph () {
            if (current.block_type == BlockType.PARAGRAPH) {
                current.close ();
                current = current.parent;
            }
        }

        private void add_block (Block block) {
            if (current.block_type == BlockType.DOCUMENT || current.block_type == BlockType.QUOTE || current.block_type == BlockType.LIST_ITEM) {
                if (block.block_type == BlockType.IMAGE && current.children.size > 0) {
                    var last = current.children.get (current.children.size - 1);
                    if (last.block_type == BlockType.GALLERY && last.open) {
                        last.add_child (block);
                        return;
                    } else if (last.block_type == BlockType.IMAGE) {
                        current.children.remove_at (current.children.size - 1);
                        var gallery = new Block (BlockType.GALLERY, last.indent);
                        gallery.add_child (last);
                        gallery.add_child (block);
                        current.add_child (gallery);
                        return;
                    }
                }
                current.add_child (block);
            } else if (current.parent != null) {
                current.close ();
                current = current.parent;
                add_block (block);
            }
        }

        private void process_line (string line) {
            int indent = get_indent (line);
            string trimmed = line.strip ();

            if (current.block_type == BlockType.CODE_BLOCK && current.open) {
                if (trimmed.has_prefix ("```")) {
                    current.close ();
                    current = current.parent;
                } else {
                    if (current.indent >= 4 && line.has_prefix ("    ")) {
                        current.content += line.substring (4) + "\n";
                    } else {
                        current.content += line + "\n";
                    }
                }
                return;
            }

            if (current.block_type == BlockType.MATH && current.open) {
                if (trimmed.has_suffix ("$$")) {
                    current.content += line.replace ("$$", "").strip ();
                    current.close ();
                    current = current.parent;
                } else {
                    current.content += line + "\n";
                }
                return;
            }

            if (current.block_type == BlockType.TABLE && current.open) {
                if (trimmed.has_prefix ("|")) {
                    current.content += trimmed + "\n";
                    return;
                } else {
                    current.close ();
                    current = current.parent;
                }
            }

            if (trimmed == "") {
                if (current.block_type == BlockType.PARAGRAPH) {
                    current.close ();
                    current = current.parent;
                } else if (current.block_type == BlockType.CODE_BLOCK && current.open) {
                    current.content += "\n";
                } else if (current.block_type == BlockType.LIST_ITEM || current.block_type == BlockType.LIST) {
                    var temp = current;
                    while (temp != root && temp.block_type == BlockType.PARAGRAPH) {
                        temp.close ();
                        temp = temp.parent;
                    }
                    current = temp;
                }
                return;
            }

            // Move up if indentation decreased
            while (current != root && indent < current.indent && current.block_type != BlockType.CODE_BLOCK) {
                current.close ();
                current = current.parent;
            }

            // Footnote continuation
            if (last_footnote_id != null && indent > 0) {
                string existing = footnotes.get (last_footnote_id);
                footnotes.set (last_footnote_id, existing + "\n" + trimmed);
                return;
            }

            // Indented Code Block
            if (indent >= 4 && trimmed != "" && !(current.block_type == BlockType.PARAGRAPH && current.open) && !(current.block_type == BlockType.LIST_ITEM) && !(current.block_type == BlockType.LIST)) {
                if (current.block_type == BlockType.CODE_BLOCK && current.open) {
                    current.content += line.substring (4) + "\n";
                } else {
                    close_paragraph ();
                    var cb = new Block (BlockType.CODE_BLOCK, indent);
                    cb.content = line.substring (4) + "\n";
                    add_block (cb);
                    current = cb;
                }
                return;
            }

            // Thematic break
            bool is_thematic = false;
            if (Regex.match_simple ("^(\\s*\\*\\s*){3,}$|^(\\s*_\\s*){3,}$", trimmed)) {
                is_thematic = true;
            } else if (Regex.match_simple ("^(\\s*-\\s*){3,}$", trimmed)) {
                if (trimmed.contains (" ") || !(current.block_type == BlockType.PARAGRAPH && current.open)) {
                    is_thematic = true;
                }
            }

            if (is_thematic) {
                 close_paragraph ();
                 add_block (new Block (BlockType.THEMATIC_BREAK, indent));
                 return;
            }

            // Setext Heading (Level 1)
            if (trimmed != "" && Regex.match_simple ("^=+ *$", trimmed) && current.block_type == BlockType.PARAGRAPH && current.open) {
                current.block_type = BlockType.HEADING;
                current.level = 1;
                current.close ();
                current = current.parent;
                return;
            }

            // Setext Heading (Level 2)
            if (trimmed != "" && Regex.match_simple ("^-+ *$", trimmed) && current.block_type == BlockType.PARAGRAPH && current.open) {
                current.block_type = BlockType.HEADING;
                current.level = 2;
                current.close ();
                current = current.parent;
                return;
            }

            // Table detection
            if (trimmed.has_prefix ("|") && Regex.match_simple ("^\\|[\\| :\\-]+\\|$", trimmed)) {
                if (current.block_type == BlockType.PARAGRAPH && current.open && current.content.strip ().has_prefix ("|")) {
                    string header = current.content.strip ();
                    current.block_type = BlockType.TABLE;
                    current.content = header + "\n" + trimmed + "\n";
                    return;
                }
            }

            // Footnote definition
            try {
                var footnote_def_regex = new Regex ("^\\[\\^(.*?)\\]:\\s*(.*)$");
                MatchInfo match_info;
                if (footnote_def_regex.match (trimmed, 0, out match_info)) {
                    close_paragraph ();
                    string id = match_info.fetch (1);
                    string content = match_info.fetch (2);
                    footnotes.set (id, content);
                    last_footnote_id = id;
                    return;
                }
            } catch (Error e) {}

            // Reference definition
            try {
                var ref_def_regex = new Regex ("^\\[(.*?)\\]:\\s*(\\S+)(?:\\s+.*)?$");
                MatchInfo match_info;
                if (ref_def_regex.match (trimmed, 0, out match_info)) {
                    close_paragraph ();
                    string id = match_info.fetch (1).down ();
                    string url = match_info.fetch (2);
                    references.set (id, url);
                    last_footnote_id = null;
                    return;
                }
            } catch (Error e) {}

            if (indent == 0) last_footnote_id = null;

            // Fenced code block
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
                    math_block.close ();
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
                while (level < trimmed.length && trimmed[level] == '#') level++;
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
                string q_trimmed = trimmed;
                while (q_trimmed.has_prefix (">")) {
                    quote_level++;
                    q_trimmed = q_trimmed.substring (1).strip ();
                }

                int curr_q_level = 0;
                Block? temp = current;
                while (temp != null && temp != root) {
                    if (temp.block_type == BlockType.QUOTE) curr_q_level++;
                    temp = temp.parent;
                }

                while (curr_q_level < quote_level) {
                    var new_quote = new Block (BlockType.QUOTE, indent);
                    add_block (new_quote);
                    current = new_quote;
                    curr_q_level++;
                }

                while (curr_q_level > quote_level && current != root) {
                    current.close ();
                    current = current.parent;
                    if (current.block_type == BlockType.QUOTE) curr_q_level--;
                }
                
                while (current != root && current.block_type != BlockType.QUOTE) {
                    current.close ();
                    current = current.parent;
                }

                if (q_trimmed != "") {
                    if (q_trimmed.has_prefix ("-- ") || q_trimmed.has_prefix ("— ")) {
                        current.content = q_trimmed.substring (q_trimmed.has_prefix ("-- ") ? 3 : 2).strip ();
                    } else {
                        var para = new Block (BlockType.PARAGRAPH, indent + 1);
                        para.content = q_trimmed;
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
                if (current.block_type == BlockType.LIST_ITEM && indent <= current.indent) {
                     current = current.parent;
                }

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
                    current.close ();
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

            // Image block
            try {
                var img_regex = new Regex ("^!\\[(.*?)\\]\\((.*?)\\)$");
                MatchInfo match_info;
                if (img_regex.match (trimmed, 0, out match_info)) {
                    close_paragraph ();
                    var image_block = new Block (BlockType.IMAGE, indent);
                    image_block.alt = match_info.fetch (1);
                    image_block.content = match_info.fetch (2);
                    add_block (image_block);
                    return;
                }
            } catch (Error e) {}

            // Paragraph or continuation
            if (current.block_type == BlockType.PARAGRAPH && current.open) {
                current.content += "\n" + trimmed;
            } else if (current.block_type == BlockType.LIST_ITEM) {
                if (indent <= current.indent) {
                    Block? temp = current;
                    while (temp != root && (temp.block_type == BlockType.LIST_ITEM || temp.block_type == BlockType.LIST)) {
                        temp.close ();
                        temp = temp.parent;
                    }
                    current = temp;
                }

                if (current.block_type != BlockType.LIST_ITEM) {
                    var para_after_list = new Block (BlockType.PARAGRAPH, indent);
                    para_after_list.content = trimmed;
                    add_block (para_after_list);
                    current = para_after_list;
                    return;
                }

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
    }
}
