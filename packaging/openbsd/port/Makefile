# LM4BSD BEGIN ADDITION — Local OpenBSD port of the complete candidate source.
COMMENT =		graphical file and folder comparison and merging
DISTNAME =		libremerge-1.6.0
CATEGORIES =		textproc
HOMEPAGE =		https://github.com/AlfredoLlaquet/libremerge-bsd

# GPLv3+; bundled component licenses are included with the package.
PERMIT_PACKAGE =	Yes

# prepare-port.sh stages the same source archive supplied with the binary.
DISTFILES =		${DISTNAME}-source.tar.gz
FETCH_MANUALLY =	"Use packaging/openbsd/prepare-port.sh with the matching source archive."
.if exists(${.CURDIR}/candidate.mk)
.include "${.CURDIR}/candidate.mk"
.endif

COMPILER =		base-clang ports-gcc
MODULES =		devel/cmake
BUILD_DEPENDS =		devel/boost \
			devel/gtest \
			devel/re2c \
			graphics/vulkan-headers
LIB_DEPENDS =		archivers/libarchive \
			devel/pcre2 \
			textproc/icu4c \
			textproc/libutf8proc \
			x11/qt6/qtbase
RUN_DEPENDS =		devel/desktop-file-utils \
			x11/gtk+4,-guic \
			x11/qt6/qtimageformats \
			x11/qt6/qtsvg \
			x11/qt6/qttranslations
WANTLIB +=		${COMPILER_LIBCXX} GL Qt6Concurrent Qt6Core Qt6DBus
WANTLIB +=		Qt6Gui Qt6Widgets archive c icui18n icuuc m pcre2-8
WANTLIB +=		pthread utf8proc z

CONFIGURE_ARGS +=	-DCMAKE_INSTALL_PREFIX=${PREFIX} \
			-DCMAKE_REQUIRE_FIND_PACKAGE_Qt6=ON \
			-DFETCHCONTENT_FULLY_DISCONNECTED=ON \
			-DLM_OPENBSD_DISTFILES=${WRKSRC}/distfiles
TEST_ENV +=		QT_QPA_PLATFORM=offscreen

post-install:
	${INSTALL_DATA_DIR} ${PREFIX}/share/licenses/libremerge
	${INSTALL_DATA} ${WRKSRC}/LICENSE ${WRKSRC}/docs/VENDORED.md \
	    ${PREFIX}/share/licenses/libremerge/
	${INSTALL_DATA} ${WRKSRC}/engine/Externals/xdiff/COPYING \
	    ${PREFIX}/share/licenses/libremerge/xdiff-COPYING

.include <bsd.port.mk>
# LM4BSD END
