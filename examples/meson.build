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

endif
