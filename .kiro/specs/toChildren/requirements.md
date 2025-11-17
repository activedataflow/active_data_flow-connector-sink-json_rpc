# Requirements Document

## Introduction

This document specifies the requirements for a Rails 8 library that implements a data transformation system.

## Requirements

It should introduce a new top-level folder to a RAILS application (./data_flow) where developer define SOURCE, SINK, and RUNTIME characteristics of their data flow requirements.

It should introduce new controllers for the defined dataflows that provide application users the ability to manage and monitor those data flows.

It should introduce a new RAILS engine (Heartbeat) that is triggered periodically by a REST call to allows data flows to proceed independently of any user input.

It should introduce models to store current data flow instance states.
