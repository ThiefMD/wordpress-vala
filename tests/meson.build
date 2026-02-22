test_exe = executable('test-markdown',
    [
      'test-markdown.vala',
      join_paths(meson.source_root(), 'src', 'Markdown.vala'),
    ],
    dependencies: libwordpress_deps,
    vala_args: [
        '--pkg=posix',
        '--vapidir=' + meson.source_root() + '/vapi'
        ],
    install: false
)

test('markdown-conversion', test_exe)
