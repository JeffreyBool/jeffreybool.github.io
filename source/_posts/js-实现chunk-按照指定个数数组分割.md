---
title: js 实现chunk 按照指定个数数组分割
categories: javascript
tags:
  - js
  - javascript
abbrlink: b5024495
date: 2020-06-28 12:02:50
---

```js
/**
 * @param item
 * @param num
 * @returns {*}
 */
export function split(item,num) {
    if(item.length <= 0){
      return item;
    }

    let groupSize = Math.ceil(item.length / num) ;
    return chunk(item,groupSize);
}

/**
 * @param item
 * @param size
 * @returns {*}
 */
export function chunk(item,size) {
    if(item.length <= 0 || size <= 0){
      return item;
    }

    let chunks = [];

    for(let i=0;i<item.length;i=i+size){
        chunks.push(item.slice(i,i+size));
    }

    return chunks
}

```