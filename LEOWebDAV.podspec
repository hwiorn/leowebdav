Pod::Spec.new do |s|

  s.name     = 'LEOWebDAV'
  s.version  = '1.1.0'
  s.license  = 'MIT'
  s.summary  = 'iOS WebDAV client library: LEOWebDAV'
  s.homepage = 'https://github.com/hwiorn/LEOWebDAV'
  s.author   = { 'leyleo' => 'liuley@163.com' }

  s.source   = { :git => 'https://github.com/hwiorn/leowebdav.git', :tag => 'master' }
  s.description  = 'iOS WebDAV client library'

  s.source_files = 'LEOWebDAV/**/*.{h,m}'
  s.frameworks = 'Foundation'

end
