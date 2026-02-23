if get_option('shared_lib')
  libtype = 'shared_library'
else
  libtype = 'static_library'
endif

libwordpress_sources = [
  'Wordpress.vala',
  'WordpressRest.vala',
  'Markdown.vala'
]


confh = configuration_data ()
confh.set_quoted('PACKAGE_LOCALE_DIR', join_paths(get_option('prefix'), get_option('datadir'), 'locale'))
confh.set_quoted('GETTEXT_PACKAGE', 'wordpress')
confh.set_quoted('VERSION', meson.project_version())
configure_file(output : 'config.h',
  configuration : confh)

inc_libh = include_directories ('.')
inc_libh_dep = declare_dependency (include_directories : inc_libh)

libwordpress = build_target('wordpress',
    sources: libwordpress_sources,
    dependencies: libwordpress_deps,
    vala_args: [
        '--pkg=posix',
        '--vapidir=' + meson.source_root() + '/vapi'
        ],
    target_type: libtype,
    vala_header: 'wordpress.h',
    vala_vapi: 'wordpress.vapi',
    c_args: [ '-include', meson.current_build_dir() + '/config.h', '-w'],
    install_dir: [true, true, true],
    install: true,
)

libwordpress_dep = declare_dependency(
  include_directories: include_directories('.'),
            link_with: libwordpress,
)

pkg = import('pkgconfig')
pkg.generate(
    libraries: libwordpress,
      version: meson.project_version(),
         name: 'wordpress',
  description: 'Publish to Wordpress.',
)
