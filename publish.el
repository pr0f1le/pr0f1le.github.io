;;; publish.el --- 博客发布配置 -*- lexical-binding: t; -*-

;;; Commentary:
;; org-publish 发布配置，供本地和 CI 共用。
;; 本地：由 init-org.el 加载；CI：在 workflow 中 load 本文件后调用 org-publish-all。

;;; Code:

;; 本文件所在目录即博客仓库根目录
(defconst blog-root-dir
  (file-name-directory (or load-file-name buffer-file-name))
  "博客仓库根目录（publish.el 所在目录）。")

(defconst org-post-dir      (expand-file-name "post/" blog-root-dir))
(defconst org-html-out      (expand-file-name "html/" blog-root-dir))
(defconst org-setupfile-dir (expand-file-name "setupfiles/" blog-root-dir))
(defconst org-site-dir      (expand-file-name "site/" blog-root-dir))
(defconst org-level-site    (expand-file-name "level-site.org" org-setupfile-dir))
(defconst org-level-post    (expand-file-name "level-post.org" org-setupfile-dir))

(require 'ox-publish)
(require 'htmlize)

;; 代码块高亮：css 模式下颜色由 code.css 提供，htmlize 只需用 font-lock
;; 做语法分析并生成 class。batch 模式下 font-lock 默认关闭，需手动开启。
(setq org-html-htmlize-output-type 'css)
(unless (display-graphic-p)
  (global-font-lock-mode 1))

(defconst html-preamble
  "<nav class=\"navbar\">
   <a href=\"/\">首页</a>
   <a href=\"/about.html\">关于</a>
   </nav>")

(defun my/org-html-post-meta (html backend info)
  "在文档标题下方插入作者与日期元信息。"
  (when (org-export-derived-backend-p backend 'html)
    (let* ((author (org-export-data (plist-get info :author) info))
           (date (org-export-data (plist-get info :date) info))
           (items (delq nil
                        (list (and (org-string-nw-p author) author)
                              (and (org-string-nw-p date) date)))))
      (when items
        (replace-regexp-in-string
         "<h1 class=\"title\">\\([^<]*\\)</h1>"
         (concat "<h1 class=\"title\">\\1</h1>\n"
                 "<div class=\"post-meta\">"
                 (mapconcat (lambda (s) (format "<span>%s</span>" s))
                            items
                            "<span class=\"separator\"> · </span>")
                 "</div>")
         html t)))))

(add-to-list 'org-export-filter-final-output-functions #'my/org-html-post-meta)

(defun my/sitemap-entry (file style project)
  (let* ((date (org-publish-find-date file project))
         (date-str (if (stringp date)
                       date
                     (format-time-string "%Y-%m-%d" date)))
         (title (org-publish-find-title file project)))
    (format "[[file:%s][[%s] %s]]" file date-str title)))

(defun my/sitemap-builder (title list)
  (concat "#+TITLE: " title "\n"
          "#+SETUPFILE: " (file-relative-name org-level-site org-site-dir) "\n\n"
          (org-list-to-org list)))

(setq org-publish-project-alist
      `(;; 文章
        ("org-posts"
         :base-directory ,org-post-dir
         :base-extension "org"
         :publishing-directory ,org-html-out
         :recursive t
         :publishing-function org-html-publish-to-html
         :headline-levels 4
         :with-author t
         :auto-preamble t
         :auto-sitemap t
         :sitemap-filename ,(file-relative-name (expand-file-name "index.org" org-site-dir) org-post-dir)
         :sitemap-title "Posts"
         :sitemap-style list
         :sitemap-format-entry my/sitemap-entry
         :sitemap-sort-files anti-chronologically
         :sitemap-function my/sitemap-builder
         :html-preamble ,html-preamble
         :html-postamble nil)
        ;; 文章静态资源
        ("static"
         :base-directory ,org-post-dir
         :base-extension "png\\|jpg\\|gif\\|pdf\\|mp3\\|ogg\\|swf"
         :publishing-directory ,org-html-out
         :recursive t
         :publishing-function org-publish-attachment)
        ;; 站点页面（sitemap、about 等）
        ("org-site"
         :base-directory ,org-site-dir
         :base-extension "org"
         :publishing-directory ,org-html-out
         :recursive nil
         :publishing-function org-html-publish-to-html
         :with-author nil
         :auto-sitemap nil
         :auto-preamble t
         :html-preamble ,html-preamble
         :html-postamble nil)
        ;; css/js
        ("style"
         :base-directory ,org-site-dir
         :base-extension "css\\|js\\|ico"
         :publishing-directory ,org-html-out
         :recursive t
         :publishing-function org-publish-attachment)
        ;; 组合
        ("org" :components ("org-posts" "org-site" "static" "style"))))

(defun blog-publish ()
  "重新发布整个博客。"
  (interactive)
  (org-publish-all t))

(provide 'publish)
;;; publish.el ends here
