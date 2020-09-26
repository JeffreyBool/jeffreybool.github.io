echo -e "\033[32m 开始编译 \033[0m"
hexo clean
hexo g && hexo d
echo "\033[32m 编译发布成功 \033[0m"