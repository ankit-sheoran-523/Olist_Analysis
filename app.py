import pandas as pd
import numpy as np
import joblib
import matplotlib.pyplot as plt
import streamlit as st
import plotly.io as pio


st.set_page_config(page_title="Olist Market Analysis", layout="wide")

st.markdown(
    """
    <style>
    .block-container {
        max-width: 70%;
        margin: auto;
    }
    </style>
    """,
    unsafe_allow_html=True
)

st.header("Olist Marketplace Analysis",text_alignment="center",divider=True)
st.markdown('---')



t1,t2,t3=st.tabs(["Insights","Analysis","Prediction"])
with t1: 
    

    col1, col2 = st.columns([1,1.75])
    with col1:
        st.write("◉ We have `9` dataset tables as ")
        st.markdown("- `Customers`")
        st.markdown("- `Geolocation`")
        st.markdown("- `Order Items`")
        st.markdown("- `Order Payments`")
        st.markdown("- `Order Reviews`")
        st.markdown("- `Orders`")
        st.markdown("- `Products`")
        st.markdown("- `Sellers`")
        st.markdown("- `Product Category Translated`")
    with col2:
        st.image('Data_Overview_and_MetaData/HRhd2Y0.png',caption="Tables and there relationships",width=700)


    #################### INSIGHTS###############################################
    st.subheader("Select Dataset")
    tab1,tab2,tab3,tab4,tab5,tab6=st.tabs(["Sellers and Customers","Order items","Order Payments","Order Reviews","Orders","Products and translation"])
    with tab1:
        st.subheader('Customer Table -')
        st.markdown('◉ Have `99441` rows and `5` columns)')
        st.markdown('◉ And `96096` Total customers')
        st.write("◉ columns are - `customer_id`, `customer_unique_id`, `customer_zip_code_prefix`, `customer_city`, `customer_state`")
        st.markdown("""1) we have customer_id to assign unique customer_id for customer to each order, not to identify individual customer/user.
2) customer_unique_id is assigned to each used to identtify each user individually.
3) we have cutomer_zip_code_prefix, customer_city, customer_state to get customer address.""")
        col1,col2,col3 = st.columns([0.1,5,0.1])
        with col2:
            st.image('Insights\plots_Images\Customer_insights.png',output_format="PNG",width=100000)

        st.subheader('Seller Table -')
        st.markdown('◉ Have `3095` rows and `4` columns)')
        st.markdown('◉ And `3095` Total sellers')
        st.write("◉ Have columns - `seller_id`, `seller_zip_code_prefix`, `seller_city`, `seller_state`")
        st.markdown("""1) we have seller_id to uniquely identify the seller.
2) and seller_zip_code_prefix, seller_city, seller_state to get seller location.""")
        col1,col2,col3 = st.columns([0.1,5,0.1])
        with col2:
            st.image('Insights\plots_Images\sellers_insights.png',output_format="PNG",width=100000)

    with tab2:
        st.subheader('Order items Table -')
        st.markdown('◉ Have `112650` rows and `7` columns)')
        st.markdown('- `98666` Total orders placed.')
        st.markdown('- `112650` Total Products sold.')
        st.markdown('- `32951` Total unique products.')
        st.markdown('- `R$ 137.75` Average order amount')
        st.markdown('- `R$ 22.82` Average Shipping amount')
        st.write("◉ Have columns - `order_id`, `order_item_id`, `product_id`, `seller_id`, `shipping_limit_date`, `price`, `freight_value`")
        st.markdown("""1) order_id is unique value assigned to each order.
2) order_item_id is to get no. of items in each order.
3) product_id is to identify the product in each order.
4) seller_id is the product seller.
5) shipping_limit_date is date upto which the order to be provided to the carrier.
6) price is value of individual item in order.
7) freight_value are shipping charges.""")
        col1,col2,col3 = st.columns([0.1,5,0.1])
        with col2:
            st.markdown("Order price and Shipping price Distribution -")
            st.image('Insights\plots_Images\Order_item_price&Sprice_hisplot.png',output_format="PNG",width=100000)
            st.markdown("")
            st.markdown("Order Products and Sellers Distribution -")
            st.image('Insights\plots_Images\order_items_seller&product_insights.png',output_format="PNG",width=100000)

    with tab3:
        st.subheader('Order Payments Table -')
        st.markdown('◉ Have `103886` rows and `5` columns)')
        st.write("◉ Have columns - `order_id`, `order_item_id`, `product_id`, `seller_id`, `shipping_limit_date`, `price`, `freight_value`")
        st.markdown("""1) we have order id to link table.
2) payment_sequential as no. of methods used for payment
3) payment_type method of payment
4) payment_installments number of installment.
5) payment_value id order value.""")
        col1,col2,col3 = st.columns([0.1,5,0.1])
        with col2:
            st.image('Insights\plots_Images\Order_payment_histplot.png',output_format="PNG",width=100000)
            st.image('Insights\plots_Images\Order_payment_paym_analysis.png',output_format="PNG",width=100000)
            st.image('Insights\plots_Images\Order_payment_price_trend.png',output_format="PNG",width=100000)

    with tab4:
        st.subheader('Order Reviews Table -')
        st.markdown('◉ Have `99224` rows and `7` columns)')
        st.markdown('- `98410` Total Reviews submitted')
        st.markdown('- `4.08` Average Rating Score')
        st.write("◉ columns are - `review_id`, `order_id`, `review_score`, `review_comment_title`, `review_comment_message`, `review_creation_date`, `review_answer_timestamp`")
        st.markdown("""1) we have review_id assign to each order_id.
2) order_id to link tables.
3) review_score as rating.
4) review_comment_title	and review_comment_message as review.
5) review_creation_date date on which customer submitted the review.
6) review_answer_timestamp date when Olist or the seller responded to the review.""")
        col1,col2,col3 = st.columns([0.1,5,0.1])
        with col2:
            st.image('Insights\plots_Images\Review_insights.png',output_format="PNG",width=100000)

    with tab5:
            st.subheader('Orders Table -')
            st.markdown('◉ Have `99441` rows and `8` columns)')
            st.markdown('- `12.09` Average Transit time')
            st.markdown('- `0.2` Average Approval time (mostly on same day)')
            st.markdown('- `12.09` Average Transit time')
            st.markdown('- `10.62` Average Transit delay')
            st.markdown('- `0.62%` Cancellation Rate')
            st.markdown('- `90.44%` On time delivery Rate')
            st.write("◉ columns are -  `order_id`, `customer_id`, `order_status`, `order_purchase_timestamp`, `order_approved_at`, `order_delivered_carrier_date`, `order_delivered_customer_date`, `order_estimated_delivery_date`")
            st.markdown("""1) we have order_id to get individual order.
2) customer_id to get customer for individual order.
3) order_status to determine the status of order.
4) order_purchase_timestamp date time of order.
5) order_approved_at timestamp at which the order was approved
6) order_delivered_carrier_date order reached to carrier.
7) order_delivered_customer_date timestamp at which the order recieved by customer.
8) order_estimated_delivery_date estimated timestamp at which order to reach to customer.""")
            col1,col2,col3 = st.columns([0.1,5,0.1])
            with col2:
                st.markdown("Order Dates Distribution -")
                st.image('Insights\plots_Images\Orders_dates_distribution.png',output_format="PNG",width=100000)
                st.markdown("Order Status Distribution")
                st.image('Insights\plots_Images\Orders_status.png',output_format="PNG",width=100000)

    with tab6:
            st.subheader('Product Table -')
            st.markdown('◉ Have `32951` rows and `9` columns')
            st.write("◉ columns are -  `product_id`, `product_category_name`, `product_name_lenght`, `product_description_lenght`, `product_photos_qty`,`product_weight_g`, `product_length_cm`, `product_height_cm`, `product_width_cm`")
            st.markdown("""1) product_id to link tables with each other and uniquely indentify the products.
2) product_category_name, product_name_lenght, product_description_lenght deliver product information.
3) product_photos_qty number of photos available on platform.
4) product_weight_g is weight of product in grams.
5) product_length_cm, product_height_cm, product_width_cm are product dimensions.""")
            col1,col2,col3 = st.columns([0.1,5,0.1])
            with col2:
                st.markdown("Products Distribution -")
                st.image('Insights\plots_Images\products_insights.png',output_format="PNG",width=100000)

            st.subheader('Product Category Translated -')
            st.markdown('◉ Have `71` rows and `2` columns)')
            st.write("◉ columns are - `product_category_name`, `product_category_name_english`")
            st.markdown("""1) product_category_name is product category mentioned in Brazilian Portuguese.
2) product_category_name_english is translated category in English.""")

with t2:
    st.subheader('Advance Analysis Visualization - ')
    col1,col2,col3 = st.columns([0.1,5,0.1])
    with col2:

        st.write("")
        st.write("")
        st.markdown("<div style='text-align: center;'><B>Transit vs Rating</B></div>",unsafe_allow_html=True,)
        fig1 = pio.read_json("Insights/plotly/transit_vs_rating.json")
        fig1.update_layout(title=dict(text="",x=0.5))
        st.plotly_chart(fig1, use_container_width=True)

        st.write("")
        st.write("")
        fig2 = pio.read_json("Insights/plotly/RFM.json")
        fig2.update_layout(title=dict(x=0.5,xanchor="center"))
        st.plotly_chart(fig2, use_container_width=True)

        st.write("")
        st.write("")
        fig3 = pio.read_json("Insights/plotly/ABC.json")
        fig3.update_layout(title=dict(x=0.5,xanchor="center"))
        st.plotly_chart(fig3, use_container_width=True)

        st.write("")
        st.write("")
        fig4 = pio.read_json("Insights/plotly/XYZ.json")
        fig4.update_layout(title=dict(x=0.5,xanchor="center"))
        st.plotly_chart(fig4, use_container_width=True)

        st.write("")
        st.write("")
        fig5 = pio.read_json("Insights/plotly/Seller_risk.json")
        fig5.update_layout(title=dict(x=0.5,xanchor="center"))
        st.plotly_chart(fig5, use_container_width=True)

        st.write("")
        st.write("")
        fig6 = pio.read_json("Insights/plotly/State_Supply.json")
        fig6.update_layout(title=dict(x=0.5,xanchor="center"))
        st.plotly_chart(fig6, use_container_width=True)

        st.write("")
        st.write("")
        fig7 = pio.read_json("Insights/plotly/Hourly_purchase.json")
        fig7.update_layout(title=dict(x=0.5,xanchor="center"))
        st.plotly_chart(fig7, use_container_width=True)

        st.write("")
        st.write("")
        fig8 = pio.read_json("Insights/plotly/Co_products.json")
        fig8.update_layout(title=dict(x=0.5,xanchor="center"))
        st.plotly_chart(fig8, use_container_width=True)

with t3:
    ev_df=pd.read_csv('ml_model/tunned_model_evaluations.csv')
    rf_model=joblib.load('ml_model/saved_pkl_models/rf_pipeline.pkl')
    gb_model=joblib.load('ml_model/saved_pkl_models/gb_pipeline.pkl')
    xgb_model=joblib.load('ml_model/saved_pkl_models/xgb_pipeline.pkl')


    st.subheader('Prediction - ')
    st.markdown('◉ Trained various models and evaluated them on the basis of R2 score, including hyperparameter tuning and feature engineering. The models used are -')
    st.markdown('-- RandomForestRegressor(bootstrap = `True`, max_depth = `20`, min_samples_leaf = `2`, min_samples_split = `5`, n_estimators = `200`)')
    st.markdown('-- Gradient Boosting Regressor(max_depth = `7`, min_samples_leaf = `4`, min_samples_split = `5`, n_estimators = `200`)')
    st.markdown('-- XGBoost Regressor(learning_rate =  `0.1`, max_depth = `7`, n_estimators = `300`)')
    st.markdown('◉ Columns used for Training and prediction are - ')
    st.markdown('-- `seller_state`')
    st.markdown('-- `customer_state`')
    st.markdown('-- `distance_km`')
    st.markdown('-- `product_weight_g`')
    st.markdown('-- `volume_cm3`')
    st.markdown('-- `price`')
    st.markdown('◉ Trained model evaluations are - ')
    st.write(ev_df)
    st.write("")
    st.subheader("◉ Fill the below values to predict the shipping charges.")
    c1,c2=st.columns(2)
    with c1:
        seller_state=st.selectbox('Select Seller State',('SP', 'MG', 'PR', 'SC', 'DF', 'RS', 'RJ', 'GO', 'MA', 'ES', 'BA','PI', 'RO', 'MT', 'CE', 'RN', 'PE', 'MS', 'PB'),key='seller_state')
        volume_cm3=st.number_input('Product Volume in cm3',min_value=816,max_value=57200,value=1000,key='volume_cm3')
        price=st.number_input('Product Price in R$',min_value=18,max_value=360,value=100,key='price')
    with c2:
        customer_state=st.selectbox('Select Customer State',('RJ', 'SP', 'MG', 'PR', 'GO', 'BA', 'AL', 'MS', 'CE', 'DF', 'RS','PE', 'SC', 'ES', 'MA', 'PA', 'MT', 'PB', 'AM', 'AP', 'PI', 'TO','RO', 'RN', 'SE', 'AC', 'RR'),key='customer_state')
        distance_km=st.number_input('Distance in KM',min_value=17,max_value=2096,value=100,key='distance_km')
        product_weight_g=st.number_input('Product Weight in grams',min_value=125,max_value=9750,value=1000,key='product_weight_g')

        test_df=pd.DataFrame({
                'seller_state':[seller_state],
                'customer_state':[customer_state],
                'distance_km':[distance_km],
                'product_weight_g':[product_weight_g],
                'volume_cm3':[volume_cm3],
                'price':[price]
            })
    st.subheader("◉ Input values for prediction are - ")
    st.table(test_df)

    if st.button('Predict Shipping Charges'):
        rf_pred=rf_model.predict(test_df)[0]
        gb_pred=gb_model.predict(test_df)[0]
        xgb_pred=xgb_model.predict(test_df)[0]

        st.success("◉ Predicted Shipping Charges are - ")
        st.write(f"- Random Forest Regressor : `R$ {rf_pred:.2f}`")
        st.write(f"- Gradient Boosting Regressor : `R$ {gb_pred:.2f}`")
        st.write(f"- XGBoost Regressor : `R$ {xgb_pred:.2f}`")


    st.info("Pushed the R2 Score from approx **0.52** to **0.73** by using feature engineering and hyperparameter tuning.")
