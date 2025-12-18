
DJLINT_VERSION="${VERSION:-latest}"

if [ "$DJLINT_VERSION" = "latest" ]; then
    VERSION_SUFFIX="@latest"
else
    VERSION_SUFFIX="==$DJLINT_VERSION"
fi

echo "Installing djlint${VERSION_SUFFIX} via uv in $UV_TOOL_DIR"

uv tool install "djlint${VERSION_SUFFIX}"
