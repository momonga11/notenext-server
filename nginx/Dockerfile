FROM nginx:1.19.8-alpine
RUN rm -f /etc/nginx/conf.d/*
# テンプレートをデフォルトのディレクトリにコピー
COPY ./templates /etc/nginx/templates
CMD ["nginx", "-g", "daemon off;"]
