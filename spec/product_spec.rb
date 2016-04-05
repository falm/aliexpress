require 'aliexpress'

describe Aliexpress::Product do

  describe '测试速卖通商品相关接口' do

    # 获取商品的 SKU 属性
    def get_product_skus(skus)
      product_skus = []

      product_skus << Aliexpress::ProductSKU.default(skus).to_h

      product_skus
    end

    # 获取商品属性
    def get_product_properties(properties)
      product_properties = []

      properties.each do |property|
        product_properties << Aliexpress::ProductProperty.default(property)
      end

      product_properties
    end

    # 获取图片的 URL - 图片链接
    def get_image_urls
      image_key = Aliexpress::Cache.generate_key('image_urls_key')
      image_urls = Aliexpress.redis.get image_key

      if image_urls.present?
        image_urls = Marshal.load image_urls
      else
        image_urls = Aliexpress::Image.listImagePagination
        Aliexpress.redis.set image_key, Marshal.dump(image_urls)
      end

      image_urls.images.map(&:url)[0..5].join(';')
    end

    def get_freight_template_id
      freight_key = Aliexpress::Cache.generate_key('freight_key')
      freights = Aliexpress.redis.get freight_key

      if freights.present?
        freights = Marshal.load freights
      else
        freights = Aliexpress::Freight.listFreightTemplate
        Aliexpress.redis.set freight_key, freights
      end

      freights.aeopFreightTemplateDTOList.sample.templateId
    end

    it '刊登商品测试' do
      category_id = 200004358

      # 优惠券日期
      coupon_date = {
          couponStartDate: Date.new,
          couponEndDate: Date.new
      }

      # 对比两个接口的区别
      # skus = Aliexpress::Category.getAttributesResultByCateId 200002024

      # 所有的 SKU 信息
      all_sku = if Aliexpress.redis.get('test_sku') != nil
                  Marshal.load Aliexpress.redis.get('test_sku')
                else
                  Aliexpress::Category.getChildAttributesResultByPostCateIdAndPath cateId: category_id
                end

      # 所有 sku 属性 为 false 的，都是 类目属性
      product_property = all_sku.attributes.reject { |item| item.sku }

      # 获取类目属性
      product_skus = all_sku.attributes.reject { |item| item.sku == false }.sort_by(&:spec)

      options = {
          subject: 'Big_Test',
          keyword: 'testkeyword',
          categoryId: category_id, # 其他特殊类中的其他测试
          aeopAeProductSKUs: get_product_skus(product_skus).to_json, # 用来设置SKU属性
          aeopAeProductPropertys: get_product_properties(product_property).to_json, # 设置公共产品属性
          deliveryTime: 7,
          detail: 'bigtest123',
          freightTemplateId: get_freight_template_id, # 运费模板
          wsValidNum: 30,
          productPrice: 1.00,
          imageURLs: get_image_urls,
          # 可选字段 - optional fields
          productPrice: 123.00,
          productUnit: Aliexpress::Product::Unit::PIECE,
          packageType: false,
          lotNum: 1,
          currencyCode: 'USD',
          isPackSell: false,
          sizeChartId: 121,
          reduceStrategy: Aliexpress::ReduceStrategy::ORDER
          # bulkOrder: '',
          # bulkDiscount: ''
      }

      Aliexpress::Product.postAeProduct({}, options)
    end
  end
end