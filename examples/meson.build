if get_option('enable_examples')

  example_deps = libwordpress_deps + [ libwordpress_dep ]

  executable('hello-wordpress', 'hello-wordpress.vala',
    dependencies: example_deps,
    vala_args: [
        '--pkg=posix',
        '--vapidir=' + meson.source_root() + '/vapi'
        ],
    install: false
  )

  executable('hello-wordpress-rest',
    [
      'hello-wordpress-rest.vala',
      join_paths(meson.source_root(), 'src', 'Markdown.vala'),
      join_paths(meson.source_root(), 'src', 'Wordpress3.vala'),
    ],
    dependencies: libwordpress_deps,
    vala_args: [
        '--pkg=posix',
        '--vapidir=' + meson.source_root() + '/vapi'
        ],
    install: false
  )

endif
