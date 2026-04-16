#!/usr/bin/env bash
set -euo pipefail

# Ruby バージョン別のイメージと platform 指定
# Ruby 2.0: 公式イメージは古いマニフェスト形式のため使えず、ソースビルドした amd64 イメージを使う
# Ruby 2.2 以降: 公式 ruby:X.X イメージ
RUBY_VERSIONS=("2.0" "2.2" "2.7" "3.1" "3.3")
FAILED=()

for version in "${RUBY_VERSIONS[@]}"; do
  echo ""
  echo "========================================="
  echo " Testing Ruby ${version}"
  echo "========================================="

  image="ruby:${version}"
  platform_arg=""
  pre_install=""

  if [ "${version}" = "2.0" ]; then
    image="rspec-undefined-ruby-2.0"
    platform_arg="--platform linux/amd64"
    # Ruby 2.0 カスタムイメージが無ければビルド
    if ! docker image inspect "${image}" >/dev/null 2>&1; then
      echo "Building custom Ruby 2.0 image (takes several minutes)..."
      docker build --platform linux/amd64 -f docker/ruby-2.0.Dockerfile -t "${image}" .
    fi
  fi

  # Ruby 2.0/2.2 は Bundler 1.x が必要
  if [ "${version}" = "2.0" ] || [ "${version}" = "2.2" ]; then
    pre_install='gem install bundler -v "< 2" --no-document 2>/dev/null; '
  fi

  if docker run --rm ${platform_arg} \
    -e LANG=C.UTF-8 \
    -e LC_ALL=C.UTF-8 \
    -v "$(pwd)":/gem:ro \
    "${image}" \
    bash -c "
      set -e
      cp -r /gem /tmp/work
      cd /tmp/work
      rm -f Gemfile.lock
      ruby -v
      ${pre_install}bundle install --jobs=4 --retry=3
      bundle exec rspec
    "; then
    echo "Ruby ${version}: PASSED"
  else
    echo "Ruby ${version}: FAILED"
    FAILED+=("${version}")
  fi
done

echo ""
echo "========================================="
echo " Summary"
echo "========================================="

if [ ${#FAILED[@]} -eq 0 ]; then
  echo "All versions passed!"
else
  echo "Failed versions: ${FAILED[*]}"
  exit 1
fi
