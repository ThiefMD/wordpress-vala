if get_option('enable_examples')

  example_deps = libwordpress_deps + [ libwordpress_dep ]+ [ dependency('gtk+-3.0'), dependency('gtksourceview-3.0'), ]

  executable('hello-wordpress', 'hello-wordpress.vala',
    dependencies: example_deps,
    vala_args: [
        '--pkg=posix',
        '--vapidir=' + meson.source_root() + '/vapi'
        ],
    install: false
  )

endif
