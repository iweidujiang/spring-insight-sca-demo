package io.github.iweidujiang.scaproduct.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;

/**
 * ┌───────────────────────────────────────────────
 * │ 📦 商品管理控制器
 * │
 * │ 👤 作者：苏渡苇
 * │ 🔗 微信公众号：苏渡苇
 * │ 💻 GitHub：https://github.com/iweidujiang
 * │ 📅 @since：2026/1/18
 * └───────────────────────────────────────────────
 */
@RestController
@RequestMapping("/product")
public class ProductController {

    @GetMapping("/price/{id}")
    public BigDecimal getPrice(@PathVariable("id") Long id) {
        if (id == 1) {
            return new BigDecimal("5899");
        }
        return new BigDecimal("5999");
    }

}
