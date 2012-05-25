# coding: utf-8
module LazyHighCharts
  module LayoutHelper

    def high_chart(placeholder, object  , &block)
      object.html_options.merge!({:id=>placeholder})
      object.options[:chart][:renderTo] = placeholder
      high_graph(placeholder,object , &block).concat(content_tag("div","", object.html_options))
    end

    def high_stock(placeholder, object  , &block)
      object.html_options.merge!({:id=>placeholder})
      object.options[:chart][:renderTo] = placeholder
      high_graph_stock(placeholder,object , &block).concat(content_tag("div","", object.html_options))
    end

    def high_graph(placeholder, object, &block)
      build_html_output("Chart", placeholder, object, &block)
    end

    def high_graph_stock(placeholder, object, &block)
      build_html_output("StockChart", placeholder, object, &block)
    end

    def build_html_output(type, placeholder, object, &block)
      options_collection = []
      object.options.keys.each do |key|
        k = key.to_s.camelize.gsub!(/\b\w/) { $&.downcase }
        options_collection << "#{k}: #{object.options[key].to_json}"
      end

      # This check is put in to catch for those graphs that are time series charts.  In that event the
      # data needs to be reformated rather than just a blind JSON conversion
      if object.data.first[:data].first.class == Array and (object.data.first[:data].first.first.instance_of? DateTime or object.data.first[:data].first.first.instance_of? Date)
        series_string = "series: ["
        object.data.each do |single_series|
          series_string << "{name:'#{single_series[:name]}', data:["

          single_series[:data].each do |single_data|
            series_string << "[Date.UTC(#{single_data[0].strftime('%Y,%m,%d')}),#{single_data[1]}]"
            series_string << "," unless single_data == single_series[:data].last
          end

          series_string << "]}"
          series_string << "," unless single_series == object.data.last

        end

        series_string << "]"
        options_collection << series_string
      else
        # If this isn't a time series chart then just convert the data to JSON directly
        options_collection << "series: #{object.data.to_json}"

      end

      graph =<<-EOJS
      <script type="text/javascript">
      (function() {
        var onload = window.onload;
        window.onload = function(){
          if (typeof onload == "function") onload();
          var options, chart;
          options = { #{options_collection.join(",")} };
          #{capture(&block) if block_given?}
          chart = new Highcharts.#{type}(options);
        };
      })()
      </script>
      EOJS

      if defined?(raw)
        return raw(graph) 
      else
        return graph
      end

    end
  end
end
