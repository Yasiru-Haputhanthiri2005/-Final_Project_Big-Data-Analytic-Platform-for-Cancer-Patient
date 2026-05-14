import streamlit as st
import pyodbc
import pandas as pd
import plotly.express as px
import time
import re

# ================================================
# PAGE CONFIG
# ================================================
st.set_page_config(
    page_title="Oral Cancer Security Analytics",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ================================================
# USER ROLES
# ================================================
USERS = {
    "admin": {
        "password": "Admin@123",
        "role": "admin",
        "name": "Administrator"
    },
    "analyst": {
        "password": "Analyst@123",
        "role": "analyst",
        "name": "Data Analyst"
    },
    "viewer": {
        "password": "View@123",
        "role": "viewer",
        "name": "Healthcare Manager"
    }
}

# ================================================
# SECURITY FUNCTIONS
# ================================================
def sanitize_input(user_input):
    cleaned = re.sub(r"[';\"--]", "", str(user_input))
    return cleaned

def check_session_timeout():
    timeout = 900  # 15 minutes
    if "last_activity" in st.session_state:
        if time.time() - st.session_state.last_activity > timeout:
            st.session_state.authenticated = False
            st.session_state.role = None
            st.warning("Session expired due to inactivity. "
                      "Please login again.")
            st.rerun()
    st.session_state.last_activity = time.time()

def check_password():
    if "authenticated" not in st.session_state:
        st.session_state.authenticated = False
        st.session_state.role = None
        st.session_state.username = None
        st.session_state.failed_attempts = 0
        st.session_state.last_activity = time.time()

    if not st.session_state.authenticated:
        col1, col2, col3 = st.columns([1, 2, 1])
        with col2:
            st.title("Oral Cancer Security Analytics System")
            st.subheader("Secure Login")
            st.divider()

            username = st.text_input("Username")
            password = st.text_input("Password", type="password")

            if st.session_state.failed_attempts >= 3:
                st.error("Account locked after 3 failed attempts. "
                        "Contact administrator.")
                st.stop()

            if st.button("Login", use_container_width=True):
                clean_username = sanitize_input(username)
                clean_password = sanitize_input(password)

                if clean_username in USERS and \
                   USERS[clean_username]["password"] == clean_password:
                    st.session_state.authenticated = True
                    st.session_state.role = USERS[clean_username]["role"]
                    st.session_state.username = USERS[clean_username]["name"]
                    st.session_state.failed_attempts = 0
                    st.session_state.last_activity = time.time()
                    st.rerun()
                else:
                    st.session_state.failed_attempts += 1
                    remaining = 3 - st.session_state.failed_attempts
                    st.error(f"Invalid credentials. "
                            f"{remaining} attempts remaining.")
                    if st.session_state.failed_attempts >= 3:
                        st.error("Account locked. "
                                "Contact administrator.")
        st.stop()

# ================================================
# RUN SECURITY CHECKS
# ================================================
check_password()
check_session_timeout()

# ================================================
# DATABASE CONNECTION
# ================================================
conn = pyodbc.connect(
    "DRIVER={SQL Server};"
    "SERVER=DESKTOP-JTHSKFT\\SQLEXPRESS;"
    "DATABASE=OralcancerDWH;"
    "Trusted_Connection=yes;"
)

# ================================================
# LOAD DATA BASED ON ROLE
# ================================================
if st.session_state.role == "admin":
    anomaly_query = """
        SELECT DISTINCT PatientID, Country, Age, Gender,
            CancerStage, TumorSize, SurvivalRate,
            TreatmentType, CostUSD, EconomicBurden,
            OralCancerDiagnosis, AnomalyType
        FROM SparkAnomalyResults
    """
    audit_query = """
        SELECT TOP 100 LogID, ActionType, TableName,
            PatientKey, ActionBy, ActionDate
        FROM AuditLog
        ORDER BY ActionDate DESC
    """
    duplicate_query = """
        SELECT * FROM DuplicatePatientAlert
    """
    bulk_query = """
        SELECT * FROM BulkChangeAlert
        ORDER BY ChangeDate DESC
    """
elif st.session_state.role == "analyst":
    anomaly_query = """
        SELECT DISTINCT PatientID, Country, Age,
            CancerStage, TumorSize, SurvivalRate,
            TreatmentType, AnomalyType
        FROM SparkAnomalyResults
    """
else:  # viewer
    anomaly_query = """
        SELECT DISTINCT MaskedPatientID, Country, Age,
            CancerStage, TreatmentType, AnomalyType
        FROM SecurePatientView
    """

df = pd.read_sql(anomaly_query, conn)

# ================================================
# SIDEBAR
# ================================================
with st.sidebar:
    st.title("Navigation")
    st.write(f"User: {st.session_state.username}")
    st.write(f"Role: {st.session_state.role.upper()}")
    st.divider()

    page = st.radio("Go to", [
        "Overview Dashboard",
        "Anomaly Analysis",
        "Security Control Panel"
    ])

    st.divider()
    if st.button("Logout", use_container_width=True):
        st.session_state.authenticated = False
        st.session_state.role = None
        st.rerun()

# ================================================
# PAGE 1 - OVERVIEW DASHBOARD
# ================================================
if page == "Overview Dashboard":
    st.title("Oral Cancer Patient - Anomaly Detection Dashboard")
    st.caption(f"Logged in as: {st.session_state.username} "
              f"| Role: {st.session_state.role.upper()}")

    # KPI Cards
    st.subheader("Summary")
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Total Anomalies", len(df))
    col2.metric("Anomaly Types", df['AnomalyType'].nunique())
    col3.metric("Countries Affected", df['Country'].nunique())
    if st.session_state.role == "admin":
        col4.metric("Anomaly Rate",
                   f"{len(df)/39848*100:.1f}%")

    st.divider()

    # Bar Chart
    st.subheader("Anomalies by Type")
    type_count = df.groupby('AnomalyType').size() \
                   .reset_index(name='Count')
    fig1 = px.bar(type_count, x='AnomalyType', y='Count',
                  color='AnomalyType',
                  title="Anomaly Count by Type")
    st.plotly_chart(fig1, use_container_width=True)

    col1, col2 = st.columns(2)
    with col1:
        # Pie Chart
        st.subheader("Anomalies by Country")
        country_count = df.groupby('Country').size() \
                          .reset_index(name='Count')
        fig2 = px.pie(country_count, names='Country',
                      values='Count',
                      title="Distribution by Country")
        st.plotly_chart(fig2, use_container_width=True)

    with col2:
        # Age Distribution
        st.subheader("Age Distribution")
        fig3 = px.histogram(df, x='Age', color='AnomalyType',
                           title="Age Distribution by Anomaly Type")
        st.plotly_chart(fig3, use_container_width=True)

# ================================================
# PAGE 2 - ANOMALY ANALYSIS
# ================================================
elif page == "Anomaly Analysis":
    st.title("Anomaly Analysis")

    # Filters
    col1, col2, col3 = st.columns(3)
    with col1:
        country_filter = st.selectbox(
            "Filter by Country",
            ['All'] + df['Country'].unique().tolist()
        )
    with col2:
        anomaly_filter = st.selectbox(
            "Filter by Anomaly Type",
            ['All'] + df['AnomalyType'].unique().tolist()
        )
    with col3:
        if 'CancerStage' in df.columns:
            stage_filter = st.selectbox(
                "Filter by Cancer Stage",
                ['All'] + sorted(df['CancerStage'].unique().tolist())
            )

    # Apply filters
    filtered_df = df.copy()
    if country_filter != 'All':
        filtered_df = filtered_df[
            filtered_df['Country'] == country_filter]
    if anomaly_filter != 'All':
        filtered_df = filtered_df[
            filtered_df['AnomalyType'] == anomaly_filter]
    if 'CancerStage' in df.columns and stage_filter != 'All':
        filtered_df = filtered_df[
            filtered_df['CancerStage'] == stage_filter]

    st.metric("Filtered Records", len(filtered_df))

    # Scatter Plot
    if 'TumorSize' in df.columns and 'SurvivalRate' in df.columns:
        fig4 = px.scatter(filtered_df,
                         x='TumorSize',
                         y='SurvivalRate',
                         color='AnomalyType',
                         title="Tumor Size vs Survival Rate")
        st.plotly_chart(fig4, use_container_width=True)

    # Data Table
    st.subheader("Anomaly Records")
    st.dataframe(filtered_df)
    st.caption(f"Showing {len(filtered_df)} records")

# ================================================
# PAGE 3 - SECURITY CONTROL PANEL
# ================================================
elif page == "Security Control Panel":
    if st.session_state.role != "admin":
        st.error("Access Denied. Admin privileges required.")
        st.stop()

    st.title("Security Control Panel")
    st.warning("Admin Only — Restricted Access")

    # Security KPIs
    col1, col2, col3 = st.columns(3)
    col1.metric("Total Anomalies Detected", len(df))
    col2.metric("Anomaly Rate", f"{len(df)/39848*100:.1f}%")
    col3.metric("Countries Monitored", df['Country'].nunique())

    st.divider()

    # Audit Log
    st.subheader("Audit Log — Recent Database Activity")
    try:
        audit_df = pd.read_sql(audit_query, conn)
        st.dataframe(audit_df)
    except:
        st.info("No audit log entries yet.")

    st.divider()

    # Duplicate Detection
    st.subheader("Duplicate Patient Detection")
    try:
        dup_df = pd.read_sql(duplicate_query, conn)
        if len(dup_df) > 0:
            st.error(f"{len(dup_df)} duplicate records found!")
            st.dataframe(dup_df)
        else:
            st.success("No duplicate records detected.")
    except:
        st.info("No duplicates found.")

    st.divider()

    # Bulk Change Alert
    st.subheader("Bulk Change Monitoring")
    try:
        bulk_df = pd.read_sql(bulk_query, conn)
        if len(bulk_df) > 0:
            st.dataframe(bulk_df)
        else:
            st.success("No suspicious bulk changes detected.")
    except:
        st.info("No bulk changes recorded.")

    st.divider()

    # Anomaly Trend by Country
    st.subheader("Anomaly Distribution by Country and Type")
    country_type = df.groupby(['Country', 'AnomalyType']) \
                     .size().reset_index(name='Count')
    fig5 = px.bar(country_type, x='Country', y='Count',
                  color='AnomalyType', barmode='stack',
                  title="Stacked Anomalies by Country")
    st.plotly_chart(fig5, use_container_width=True)

conn.close()