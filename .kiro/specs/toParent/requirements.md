# Requirements Document

## Introduction

This document specifies what users (Parents) of Active Data Flow need to kow.

They should know THIS introduces a new top-level folder to a RAILS application (./data_flow) where developer define SOURCE, SINK, and RUNTIME characteristics of their data flow requirements.

They should know THIS introduces new controllers for the defined dataflows that provide application users the ability to manage and monitor those data flows.

They should know THIS introduces a new RAILS engine (Heartbeat) that is triggered periodically by a REST call to allows data flows to proceed independently of any user input.

They should know THIS introduces models to store current data flow instance states.
