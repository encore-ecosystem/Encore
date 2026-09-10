/* Encore syntax for mdBook's bundled highlight.js. No external dependencies. */
(() => {
    if (!window.hljs) return;
    hljs.registerLanguage("encore", () => ({
        name: "Encore",
        aliases: ["enq"],
        keywords: {
            keyword: "fn async await spawn struct trait enum impl for let static mut ret " +
                "while loop do continue break if elif else match pub import as dyn " +
                "extern unsafe ehir with sending frozen macro_rules",
            literal: "true false",
            type: "Self bool str u8 u16 u32 u64 usize i8 i16 i32 i64 isize f32 f64",
        },
        contains: [
            hljs.C_LINE_COMMENT_MODE,
            hljs.C_BLOCK_COMMENT_MODE,
            {className: "string", begin: /f?"/, end: /"/, contains: [hljs.BACKSLASH_ESCAPE]},
            {className: "number", begin: /\b(?:0[xX][0-9a-fA-F_]+|0[bB][01_]+|0[oO][0-7_]+|[0-9]+(?:\.[0-9]+)?)(?:_(?:[ui](?:8|16|32|64|size)|f(?:32|64)))?\b/},
            {className: "meta", begin: /#(?:attr|cfg)\b/},
        ],
    }));
    document.querySelectorAll("code.language-encore, code.language-enq").forEach((code) => {
        // mdBook may have already highlighted an unknown language by guessing.
        code.textContent = code.textContent;
        delete code.dataset.highlighted;
        if (hljs.highlightElement) hljs.highlightElement(code);
        else hljs.highlightBlock(code);
    });
})();

// Keep text readable when a desktop reader narrows an already open window.
// On small screens mdBook otherwise retains the desktop sidebar preference.
(() => {
    const narrow = window.matchMedia("(max-width: 619px)");
    const collapse = () => {
        const toggle = document.getElementById("mdbook-sidebar-toggle-anchor");
        if (narrow.matches && toggle && toggle.checked) {
            toggle.checked = false;
            toggle.dispatchEvent(new Event("change"));
        }
    };
    narrow.addEventListener("change", collapse);
    collapse();
})();
