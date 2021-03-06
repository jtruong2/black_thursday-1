require 'pry'
require_relative 'revenue'

class SalesAnalyst
  attr_reader :parent,
              :revenue

  def initialize(parent)
    @parent = parent
    @revenue = Revenue.new(self)
  end

  def average_items_per_merchant
    a = item_count_per_merchant
    value = a.values
    sum = value.reduce(:+).to_f
    leng = value.length.to_f
    average = sum / leng
    average.round(2)
  end

  def average_items_per_merchant_standard_deviation
    a = item_count_per_merchant
    value = a.values
    standard_deviation(value).round(2)
  end

  def merchants_with_high_item_count
    # x = []
    y = []
    a = item_count_per_merchant
    b = average_items_per_merchant_standard_deviation
    c = average_items_per_merchant
    d = @parent.merchants.contents
    a.each do |k,v|
      y << k if v > b + c
    end
    y.map do |i|
      d[i]
    end
  end

  def average_item_price_for_merchant(id)
    final = []
    @parent.items.contents.each do |k,v|
      if id == v.merchant_id
        final << v.unit_price
      end
    end
     total = final.reduce(:+)/final.length
     total.round(2)
  end

  def average_average_price_per_merchant
    merchants = []
    avg_prices = []
    @parent.items.contents.each do |k,v|
      if !merchants.include?(v.merchant_id)
        merchants << v.merchant_id
      end
    end
    merchants.each do |x|
      a = average_item_price_for_merchant(x)
      avg_prices << a
    end
    a = avg_prices.reduce(:+)/avg_prices.length
    a.round(2)
  end

  def golden_items
    golden = []
    a = @parent.items.contents.values.map { |v| v.unit_price}
    b = a.reduce(:+)/a.count
    c = average_price_per_merchant_standard_deviation
    d = @parent.items.contents
    @parent.items.contents.map do |k,v|
      golden << d[k] if v.unit_price.to_f > b + (c + c)
    end
    return golden
  end

  def average_invoices_per_merchant
    a = invoice_count_per_merchant
    value = a.values
    sum = value.reduce(:+).to_f
    leng = value.length.to_f
    average = sum / leng
    average.round(2)
  end

  def average_invoices_per_merchant_standard_deviation
    a = invoice_count_per_merchant
    value = a.values
    standard_deviation(value).round(2)
  end

  def top_merchants_by_invoice_count
    a = average_invoices_per_merchant
    b = average_invoices_per_merchant_standard_deviation
    c = invoice_count_per_merchant
    d = @parent.merchants.contents
    final = []
    c.find_all do |k,v|
      final << d[k] if v > a + (b + b)
    end
    return final
  end

  def bottom_merchants_by_invoice_count
    a = average_invoices_per_merchant
    b = average_invoices_per_merchant_standard_deviation
    c = invoice_count_per_merchant
    d = @parent.merchants.contents
    final = []
    c.each do |k,v|
      final << d[k] if v < a - (b + b)
    end
    return final
  end

  def top_days_by_invoice_count
    a = invoices_created_per_date
    b = average_invoices_created_per_day
    c = average_invoices_created_per_day_standard_deviation
    d = []
    a.each do |k,v|
      if v > b + c
        d << k
      end
    end
    return d
  end

  def invoice_status(status)
    count = count_status_orders
    total = count.values.reduce(:+)
    percentage = nil
    count.each do |k,v|
      if k == status
        percentage = v / total.to_f * 100
      end
    end
    percentage.round(2)
  end

  def total_revenue_by_date(date)
    @revenue.revenue_by_date[date]
  end

  def top_revenue_earners(x = nil)
    @revenue.find_earners(x)
  end

  def merchants_ranked_by_revenue
    top_revenue_earners(475)
  end

  def revenue_by_merchant(merchant_id)
    @revenue.revenue_by_merchant_id[merchant_id]
  end

  def merchants_with_pending_invoices
    @revenue.find_merchants_with_unpaid_invoices.compact
  end

  def merchants_with_only_one_item
    a = compile_items_by_merchant
    b = count_items_by_merchant(a)
    c = find_associated_merchant_instances(b)
    return c
  end

  def most_sold_item_for_merchant(merchant_id)
    a = find_successful_invoices_by_merchant(merchant_id)
    b = invoice_items_by_invoice(a)
    c = get_quantity_for_each_invoice_item(b)
    d = find_best_seller(c)
    return return_item_instances(d.keys)
  end

  def merchants_with_only_one_item_registered_in_month(month)
    merchants = merchants_with_only_one_item
    one_registered = merchants.map do |x|
      x if x.created_at.strftime("%B") == month
    end.compact
    return one_registered
  end

  def compile_items_by_merchant
    h = {}
    a = @parent.items.contents
    a.values.each do |x|
      b = @parent.items.find_all_by_merchant_id(x.merchant_id)
      h[x.merchant_id] = b
    end
    return h
  end

  def count_items_by_merchant(hash)
    i = {}
    hash.each do |k,v|
      i[k] = v.count
    end
    return i
  end

  def find_associated_merchant_instances(hash)
    j = []
    hash.each do |k,v|
      j<< k if v == 1
    end
    @revenue.find_merchant_instances(j)
  end

  def best_item_for_merchant(m_id)
    @revenue.find_best_item_for_merchant(m_id)
  end

private

  def average_price_per_merchant_standard_deviation
    a = @parent.items.contents.values.map { |v| v.unit_price}
    standard_deviation(a)
  end

  def standard_deviation(arr)
    mean = arr.reduce do |sum, element|
      sum + element
    end.to_f / arr.length
    variance = arr.reduce(0.0) do |sum, element|
      sum + (element - mean)**2
    end / (arr.length - 1)
    Math.sqrt(variance)
  end

  def item_count_per_merchant
    counts = Hash.new(0)
    x = []
    @parent.items.contents.each do |k,v|
      x << v.merchant_id
    end
    x.each do |id|
      counts[id] += 1
    end
    return counts
  end

  def invoice_count_per_merchant
    counts = Hash.new(0)
    x = []
    @parent.invoices.contents.each do |k,v|
      x << v.merchant_id
    end
    x.each do |id|
      counts[id] += 1
    end
    return counts
  end

  def days_invoice_created_at_count
    x = []
    @parent.invoices.contents.each do |k,v|
      x << v.created_at
    end
    return x
  end

  def invoices_created_per_date
    counts = Hash.new(0)
    a = days_invoice_created_at_count
    days = a.map do |x|
      x.strftime("%A")
    end
    days.each do |day|
      counts[day] += 1
    end
    return counts
  end

  def average_invoices_created_per_day
    a = invoices_created_per_date
    b = []
    a.each do |k,v|
      b << v
    end
    b.reduce(:+) / b.length
  end

  def average_invoices_created_per_day_standard_deviation
    a = invoices_created_per_date
    b = []
    a.each do |k,v|
      b << v
    end
    standard_deviation(b)
  end

  def count_status_orders
    counts = Hash.new(0)
    x = []
    @parent.invoices.contents.each do |k,v|
      x << v.status.to_sym
    end
    x.each do |id|
      counts[id] += 1
    end
    return counts
  end

  def find_successful_invoices_by_merchant(merchant_id)
    @parent.invoices.all.map do |inv|
      inv if inv.is_paid_in_full? == true && inv.merchant_id == merchant_id
    end.compact
  end

  def invoice_items_by_invoice(array)
    array.map do |x|
      @parent.invoice_items.find_all_by_invoice_id(x.id)
    end.flatten
  end

  def get_quantity_for_each_invoice_item(array)
    final = {}
    array.each do |x|
      final[x.item_id] = x.quantity
    end
    return final
  end

  def find_best_seller(hash)
    hash.select {|k,v| v == hash.values.max}
  end

  def return_item_instances(array)
    array.map do |x|
      @parent.items.find_by_id(x)
    end
  end
end
